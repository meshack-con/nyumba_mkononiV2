"""
Migration ya mara moja: kubadilisha aina za mali (property_type) kwenye
database kutoka mfumo wa zamani (apartment/nyumba/studio/villa) kwenda
mfumo mpya unaotumika na app (chumba/nyumba/kiwanja).

SABABU: Frontend (Flutter) tayari inatumia 'chumba', 'nyumba', 'kiwanja'
kama thamani za property_type (angalia lib/models/property_type.dart na
vichujio kwenye buyer_home_screen.dart), lakini enum ya database bado
ilikuwa na 'apartment'/'studio'/'villa' za zamani. Hii ndiyo iliyosababisha
kosa la "Input should be 'apartment', 'nyumba', 'studio' or 'villa'"
ulipobonyeza "Chumba" au "Kiwanja".

app/models.py tayari imesahihishwa kutumia enum mpya. Script hii
inasasisha DATA iliyokuwepo tayari kwenye database (kama ipo) kuendana
na enum mpya, kisha inaunda upya ENUM type ya Postgres.

JINSI YA KUTUMIA (mara moja tu, kabla au mara baada ya deploy ya code
mpya):

    cd backend
    pip install -r requirements.txt   # kama bado hujaweka dependencies
    DATABASE_URL="postgres://..." python migrate_property_type.py

Ni SALAMA kuendesha mara nyingi (idempotent) - haitaleta tatizo
ukiiendesha zaidi ya mara moja.
"""

import os
import sys

from sqlalchemy import create_engine, text


def main() -> None:
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        print("Weka DATABASE_URL kwanza, mfano:")
        print('  DATABASE_URL="postgres://user:pass@host/db" python migrate_property_type.py')
        sys.exit(1)

    # psycopg (v3) inahitaji "postgresql+psycopg://" badala ya "postgres://"
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql+psycopg://", 1)
    elif database_url.startswith("postgresql://"):
        database_url = database_url.replace("postgresql://", "postgresql+psycopg://", 1)

    engine = create_engine(database_url)

    with engine.begin() as conn:
        # 1) Badilisha column kuwa TEXT kwa muda, ili tuweze kusasisha
        #    thamani za zamani bila vikwazo vya ENUM type.
        conn.execute(text("ALTER TABLE properties ALTER COLUMN aina TYPE TEXT"))

        # 2) Sasisha data ya zamani kuendana na makundi matatu mapya:
        #    studio -> chumba; apartment/villa -> nyumba.
        conn.execute(text("UPDATE properties SET aina = 'chumba' WHERE aina = 'studio'"))
        conn.execute(
            text("UPDATE properties SET aina = 'nyumba' WHERE aina IN ('apartment', 'villa')")
        )

        # 3) Ondoa ENUM type ya zamani kama ipo, kisha unda mpya yenye
        #    thamani sahihi tatu, na urudishe column kutumia ENUM hiyo.
        conn.execute(text("DROP TYPE IF EXISTS property_type_old"))
        conn.execute(text("ALTER TYPE property_type RENAME TO property_type_old"))
        conn.execute(
            text("CREATE TYPE property_type AS ENUM ('chumba', 'nyumba', 'kiwanja')")
        )
        conn.execute(
            text(
                "ALTER TABLE properties "
                "ALTER COLUMN aina TYPE property_type USING aina::property_type"
            )
        )
        conn.execute(text("DROP TYPE property_type_old"))

    print("Imekamilika: property_type sasa ina 'chumba', 'nyumba', 'kiwanja' pekee.")


if __name__ == "__main__":
    main()
