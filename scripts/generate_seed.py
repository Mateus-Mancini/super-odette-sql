import pandas as pd
import re
import os
import sys
from datetime import datetime
import hashlib

# ============================================
# CONFIG
# ============================================

EXCEL_PATH = "schedule.xlsx"
VALID_YEAR = 2026
MIGRATION_DIR = "db/migration"
HASH_FILE = ".last_excel_hash"

WEEKDAY_MAP = {
    "segunda-feira": 1,
    "terça-feira": 2,
    "terça": 2,
    "quarta-feira": 3,
    "quinta-feira": 4,
    "sexta-feira": 5,
}

UNWANTED_SUBJECTS = {"intervalo", "almoço", "almoco", ""}

# ============================================
# HELPERS
# ============================================

def sql_escape(value: str) -> str:
    return str(value).replace("'", "''")

def normalize_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", str(text)).strip()

def normalize_email_name(name: str) -> str:
    parts = name.strip().split()
    if len(parts) == 1:
        base = parts[0]
    else:
        base = f"{parts[0]}.{parts[-1]}"

    return (
        base.lower()
        .replace("ã", "a")
        .replace("á", "a")
        .replace("â", "a")
        .replace("é", "e")
        .replace("ê", "e")
        .replace("í", "i")
        .replace("ó", "o")
        .replace("ô", "o")
        .replace("õ", "o")
        .replace("ú", "u")
        .replace("ç", "c")
    ) + "@institutojef.org.br"

def ensure_time_format(value: str) -> str:
    value = str(value).strip()
    if len(value) == 5:
        return value + ":00"
    return value

def compute_file_hash(path):
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()

# ============================================
# HASH CHECK
# ============================================

if not os.path.exists(EXCEL_PATH):
    print("schedule.xlsx not found.")
    sys.exit(1)

current_hash = compute_file_hash(EXCEL_PATH)

if os.path.exists(HASH_FILE):
    with open(HASH_FILE, "r") as f:
        last_hash = f.read().strip()
    if last_hash == current_hash:
        print("Excel unchanged. No migration generated.")
        sys.exit(0)

# ============================================
# EXCEL NORMALIZATION
# ============================================

xls = pd.ExcelFile(EXCEL_PATH)
sheets = xls.sheet_names

def normalize_sheet(sheet_name: str) -> pd.DataFrame:
    df = pd.read_excel(EXCEL_PATH, sheet_name=sheet_name, header=None)
    df = df.fillna("")

    normalized_rows = []
    current_class_group = None

    for r_idx in range(len(df)):
        row = df.iloc[r_idx]

        for cell in row:
            text = normalize_whitespace(cell)
            if (
                text.endswith("ANO A")
                or text.endswith("ANO B")
                or "Série" in text
                or "Srie" in text
            ):
                current_class_group = text
                break

        if any(str(c).strip().lower() == "aula" for c in row):
            weekday_by_col = {}

            for c_idx, cell in enumerate(row):
                label = normalize_whitespace(cell).lower()
                if label in WEEKDAY_MAP:
                    weekday_by_col[c_idx] = WEEKDAY_MAP[label]

            r = r_idx + 1
            while r < len(df):
                line = df.iloc[r]
                first_cell = normalize_whitespace(line.iloc[0]).lower()

                if first_cell == "aula":
                    break

                if not any(normalize_whitespace(x) for x in line):
                    r += 1
                    continue

                if "ª" in first_cell or first_cell.isdigit():
                    start_time = normalize_whitespace(line.iloc[1])
                    end_time = normalize_whitespace(line.iloc[2])
                    teacher_line = df.iloc[r + 1] if r + 1 < len(df) else None

                    for c_idx, weekday in weekday_by_col.items():
                        subject_name = normalize_whitespace(line.iloc[c_idx])
                        if not subject_name:
                            continue

                        teacher_name = ""
                        if teacher_line is not None:
                            teacher_name = normalize_whitespace(
                                teacher_line.iloc[c_idx]
                            )

                        normalized_rows.append(
                            {
                                "class_group_name": current_class_group,
                                "weekday": weekday,
                                "start_time": start_time,
                                "end_time": end_time,
                                "subject_name": subject_name,
                                "teacher_name": teacher_name,
                            }
                        )

                    r += 2
                    continue

                r += 1

    return pd.DataFrame(normalized_rows)

# ============================================
# PROCESS ALL SHEETS
# ============================================

all_rows = []
for sheet in sheets:
    df_norm = normalize_sheet(sheet)
    all_rows.append(df_norm)

if not all_rows:
    print("No data found in Excel.")
    sys.exit(1)

full_df = pd.concat(all_rows, ignore_index=True)

# ============================================
# CLEAN DATA
# ============================================

full_df["subject_name_clean"] = full_df["subject_name"].apply(normalize_whitespace)
full_df["subject_name_lower"] = full_df["subject_name_clean"].str.lower()

full_df = full_df[
    ~full_df["subject_name_lower"].isin(UNWANTED_SUBJECTS)
].copy()

full_df["class_group_name"] = full_df["class_group_name"].apply(normalize_whitespace)
full_df["teacher_name"] = full_df["teacher_name"].apply(normalize_whitespace)

full_df = full_df[full_df["teacher_name"] != ""]

full_df = full_df.sort_values(
    by=["class_group_name", "weekday", "start_time"]
).reset_index(drop=True)

if full_df.empty:
    print("No valid schedule rows after cleaning.")
    sys.exit(1)

# ============================================
# SQL GENERATION
# ============================================

sql_lines = []
sql_lines.append("-- =========================================")
sql_lines.append("-- AUTO-GENERATED FLYWAY SEED MIGRATION")
sql_lines.append("-- IDEMPOTENT / PRODUCTION SAFE")
sql_lines.append("-- =========================================")
sql_lines.append("BEGIN;")

# TURMAS
for turma_name in sorted(full_df["class_group_name"].unique()):
    sql_lines.append(f"""
INSERT INTO turma (cNmTurma, nAno)
VALUES ('{sql_escape(turma_name)}', {VALID_YEAR})
ON CONFLICT (cNmTurma, nAno)
DO NOTHING;
""")

# DISCIPLINAS
for disciplina_name in sorted(full_df["subject_name_clean"].unique()):
    sql_lines.append(f"""
INSERT INTO disciplina (cNmDisciplina)
VALUES ('{sql_escape(disciplina_name)}')
ON CONFLICT (cNmDisciplina)
DO NOTHING;
""")

# PROFESSORES + USUARIO
for professor_name in sorted(full_df["teacher_name"].unique()):
    email = normalize_email_name(professor_name)

    sql_lines.append(f"""
INSERT INTO usuario (nCdTipoUsuario, cNome, cEmail, cSenha)
VALUES (2, '{sql_escape(professor_name)}', '{sql_escape(email)}', '123456')
ON CONFLICT (cEmail)
DO NOTHING;
""")

    sql_lines.append(f"""
INSERT INTO professor (nCdUsuario)
SELECT u.nCdUsuario
FROM usuario u
WHERE u.cEmail = '{sql_escape(email)}'
ON CONFLICT DO NOTHING;
""")

# PROFESSOR_DISCIPLINA
for _, row in full_df.iterrows():
    email = normalize_email_name(row["teacher_name"])
    disciplina = row["subject_name_clean"]

    sql_lines.append(f"""
INSERT INTO professor_disciplina (nCdProfessor, nCdDisciplina)
SELECT
    p.nCdUsuario,
    d.nCdDisciplina
FROM professor p
JOIN usuario u ON u.nCdUsuario = p.nCdUsuario
JOIN disciplina d ON d.cNmDisciplina = '{sql_escape(disciplina)}'
WHERE u.cEmail = '{sql_escape(email)}'
ON CONFLICT (nCdProfessor, nCdDisciplina)
DO NOTHING;
""")

# GRADE (FIXED JOIN)
for _, row in full_df.iterrows():
    turma = row["class_group_name"]
    disciplina = row["subject_name_clean"]
    email = normalize_email_name(row["teacher_name"])

    start_time = ensure_time_format(row["start_time"])
    end_time = ensure_time_format(row["end_time"])
    weekday = int(row["weekday"])

    sql_lines.append(f"""
INSERT INTO grade (
    nCdTurma,
    nCdDisciplina,
    nCdProfessor,
    tHrInicio,
    tHrFim,
    iDiaSemana
)
SELECT
    t.nCdTurma,
    d.nCdDisciplina,
    p.nCdUsuario,
    '{start_time}',
    '{end_time}',
    {weekday}
FROM turma t
JOIN disciplina d 
    ON d.cNmDisciplina = '{sql_escape(disciplina)}'
JOIN usuario u 
    ON u.cEmail = '{sql_escape(email)}'
JOIN professor p 
    ON p.nCdUsuario = u.nCdUsuario
WHERE t.cNmTurma = '{sql_escape(turma)}'
ON CONFLICT (
    nCdTurma,
    nCdDisciplina,
    nCdProfessor,
    tHrInicio,
    tHrFim,
    iDiaSemana
)
DO NOTHING;
""")

sql_lines.append("COMMIT;")

# ============================================
# WRITE MIGRATION
# ============================================

os.makedirs(MIGRATION_DIR, exist_ok=True)

timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
filename = f"V{timestamp}__seed_schedule.sql"
migration_path = os.path.join(MIGRATION_DIR, filename)

with open(migration_path, "w", encoding="utf-8") as f:
    f.write("\n".join(sql_lines))

with open(HASH_FILE, "w") as f:
    f.write(current_hash)

print(f"Migration generated: {migration_path}")