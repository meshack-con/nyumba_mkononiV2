import re

# 1. requirements.txt
req_path = "backend/requirements.txt"
with open(req_path) as f:
    req = f.read()
if "cloudinary" not in req:
    req = req.rstrip("\n") + "\ncloudinary\n"
    with open(req_path, "w") as f:
        f.write(req)
    print("OK: requirements.txt updated")
else:
    print("SKIP: cloudinary already in requirements.txt")

# 2. database.py - add cloudinary settings
db_path = "backend/app/database.py"
with open(db_path) as f:
    db = f.read()
old_settings_line = '    cors_origins: str = "http://localhost:3000,http://localhost:8080"\n'
new_settings_block = old_settings_line + (
    '    cloudinary_cloud_name: str = ""\n'
    '    cloudinary_api_key: str = ""\n'
    '    cloudinary_api_secret: str = ""\n'
)
if old_settings_line in db and "cloudinary_cloud_name" not in db:
    db = db.replace(old_settings_line, new_settings_block, 1)
    with open(db_path, "w") as f:
        f.write(db)
    print("OK: database.py updated")
elif "cloudinary_cloud_name" in db:
    print("SKIP: database.py already has cloudinary settings")
else:
    print("ERROR: could not find target line in database.py -- no changes made")

# 3. main.py - add cloudinary import/config + replace save_upload
main_path = "backend/app/main.py"
with open(main_path) as f:
    main = f.read()

changed = False

old_import_block = "from .admin import router as admin_router\n"
new_import_block = "import cloudinary\nimport cloudinary.uploader\n\nfrom .admin import router as admin_router\n"
if old_import_block in main and "import cloudinary" not in main:
    main = main.replace(old_import_block, new_import_block, 1)
    changed = True

old_mount_block = (
    'app = FastAPI(title="Nyumba Mkononi API", version="1.0.0")\n'
    'app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")\n'
    'app.include_router(admin_router)\n'
)
new_mount_block = (
    'app = FastAPI(title="Nyumba Mkononi API", version="1.0.0")\n'
    'app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")\n'
    'app.include_router(admin_router)\n\n'
    'cloudinary.config(\n'
    '    cloud_name=settings.cloudinary_cloud_name,\n'
    '    api_key=settings.cloudinary_api_key,\n'
    '    api_secret=settings.cloudinary_api_secret,\n'
    '    secure=True,\n'
    ')\n'
)
if old_mount_block in main and "cloudinary.config" not in main:
    main = main.replace(old_mount_block, new_mount_block, 1)
    changed = True

old_save_upload = '''async def save_upload(upload: UploadFile, folder: str) -> str:
    extension = Path(upload.filename or "").suffix.lower()
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}
    if extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Aina ya file hairuhusiwi")
    target_dir = UPLOADS_DIR / folder
    target_dir.mkdir(exist_ok=True)
    filename = f"{uuid4().hex}{extension}"
    target = target_dir / filename
    target.write_bytes(await upload.read())
    return f"/uploads/{folder}/{filename}"
'''
new_save_upload = '''async def save_upload(upload: UploadFile, folder: str) -> str:
    extension = Path(upload.filename or "").suffix.lower()
    allowed_extensions = {".jpg", ".jpeg", ".png", ".webp", ".pdf"}
    if extension not in allowed_extensions:
        raise HTTPException(status_code=400, detail="Aina ya file hairuhusiwi")
    contents = await upload.read()
    resource_type = "raw" if extension == ".pdf" else "image"
    result = cloudinary.uploader.upload(
        contents,
        folder=f"nyumba_mkononi/{folder}",
        resource_type=resource_type,
        public_id=uuid4().hex,
    )
    return result["secure_url"]
'''
if old_save_upload in main and "cloudinary.uploader.upload" not in main:
    main = main.replace(old_save_upload, new_save_upload, 1)
    changed = True

if changed:
    with open(main_path, "w") as f:
        f.write(main)
    print("OK: main.py updated")
else:
    print("SKIP or ERROR: main.py -- check output above for details")

print("\nDONE. Angalia ujumbe wa juu -- kila mstari lazima useme OK.")
