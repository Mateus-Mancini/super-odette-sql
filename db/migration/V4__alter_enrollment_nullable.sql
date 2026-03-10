ALTER TABLE matricula
    ALTER COLUMN nCdTurma DROP NOT NULL;

ALTER TABLE matricula
    DROP CONSTRAINT uq_matricula;

CREATE UNIQUE INDEX uq_matricula_enrolled
    ON matricula (nCdAluno, nCdTurma)
    WHERE nCdTurma IS NOT NULL;

CREATE UNIQUE INDEX uq_matricula_pending
    ON matricula (nCdAluno)
    WHERE iStatus = 'PENDING';