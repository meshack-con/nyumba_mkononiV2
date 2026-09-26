"""
Migration ya marekebisho: kusahihisha ENUM ya property_type kwenye
database iwe na thamani za HERUFI KUBWA (CHUMBA, NYUMBA, KIWANJA)
badala ya herufi ndogo (chumba, nyumba, kiwanja).

SABABU: migrate_property_type.py (script iliyotangulia) iliunda ENUM
kwa herufi ndogo, lakini SQLAlchemy - kwa default - hutuma JINA la
enum member (mfano "CHUMBA") kwenda database, SIYO thamani yake
(mfano "chumba"), isipokuwa umeweka `values_callable` kwenye
mapped_column (models.py haina hiyo). Ndiyo maana enums nyingine
zote (property_status, user_role, n.k, zilizoundwa kiotomatiki na
`Base.metadata.create_all()`) tayari zina herufi kubwa na
zinafanya kazi vizuri - property_type peke yake ilikuwa tofauti.

Hitilafu iliyokuwa ikitokea: "invalid input value for enum
property_type: CHUMBA".

JINSI YA KUTUMIA (mara moja tu):

    cd backend
    pip install -r requirements.txt
    DATABASE_URL="postgres://..." python fix_property_type_case.py

Ni SALAMA kuiendesha zaidi ya mara moja (idempotent).
"""

import os
import sys

from sqlalchemy import create_engine, text


def main() -> None:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("Weka DATABASE_URL kwanza, mfano:")
        print('  DATABASE_URL="postgres://user:pass@host/db" python fix_property_type_case.py')
        sys.exit(1)

    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+psycopg://", 1)
    elif database_url.startswith("postgresql://"):
        database_url = database_url.replace("postgresql://", "postgresql+psycopg://", 1)

    engine = create_engine(database_url)

    with engine.begin() as conn:
        # 1) Column iwe TEXT kwa muda ili tuweze kusasisha data bila
        #    vikwazo vya ENUM ya sasa (herufi ndogo).
        conn.execute(text("ALTER TABLE properties ALTER COLUMN aina TYPE TEXT"))

        # 2) Geuza data iliyopo (herufi ndogo) kuwa herufi kubwa.
        conn.execute(text("UPDATE properties SET aina = UPPER(aina)"))

        # 3) Unda upya ENUM type yenye herufi kubwa, sawa na jinsi
        #    SQLAlchemy inavyotuma data kwa default.
        conn.execute(text("DROP TYPE IF EXISTS property_type_old"))
        conn.execute(text("ALTER TYPE property_type RENAME TO property_type_old"))
        conn.execute(
            text("CREATE TYPE property_type AS ENUM ('CHUMBA', 'NYUMBA', 'KIWANJA')")
        )
        conn.execute(
            text(
                "ALTER TABLE properties "
                "ALTER COLUMN aina TYPE property_type USING aina::property_type"
            )
        )
        conn.execute(text("DROP TYPE property_type_old"))

    print("Imekamilika: property_type sasa ina 'CHUMBA', 'NYUMBA', 'KIWANJA' (herufi kubwa).")


if __name__ == "__main__":
    main()
