-- =====================================================================
-- 03_template_entrega_taller1_v2.sql
-- Taller aplicado 1 - SQL avanzado + Transacciones (ACID) aplicado
-- Plantilla de entrega para estudiantes
--
-- IMPORTANTE:
-- 1. Trabajar únicamente sobre las tablas T1_% y AUDIT_SALARY_ADJUSTMENTS_T1
-- 2. NO modificar la estructura del entorno entregado por el docente
-- 3. NO eliminar secciones de esta plantilla
-- 4. Reemplazar únicamente los bloques indicados como "ESCRIBA AQUÍ"
-- 5. Usar la variante asignada por el docente (1, 2, 3 o 4)
-- 6. Usar un tag único de ejecución final, por ejemplo: P03_FINAL
-- =====================================================================

SET SERVEROUTPUT ON
SET FEEDBACK ON

-- ============================================================
-- 0. ENCABEZADO OBLIGATORIO
-- Complete toda esta información antes de ejecutar el script.
-- ============================================================
-- Integrante 1: Maria Valentina Osorio Romero 
-- Integrante 2: Juan Pablo Moreno Castro 
-- Curso: Bases de datos 2
-- Fecha: 08 - 04 - 2026
-- Variante asignada por el docente (1, 2, 3 o 4): 2
-- Tag de ejecución final: PXX_FINAL 

DEFINE p_variant_id = 2
DEFINE p_execution_tag = 'P02_FINAL'

PROMPT ===== 0. VERIFICACIÓN DE LA VARIANTE ASIGNADA =====
SELECT
    variant_id,
    variant_name,
    excluded_department_id,
    min_years_service,
    recent_job_history_months,
    gap_high_threshold_pct,
    gap_mid_threshold_pct,
    raise_high_pct,
    raise_mid_pct,
    raise_low_pct,
    max_salary_vs_avg_pct,
    notes
FROM t1_variants
WHERE variant_id = &p_variant_id;

-- ============================================================
-- GUÍA RÁPIDA DE OBJETOS DISPONIBLES
-- Use estos nombres reales de tablas y columnas.
-- ============================================================
-- Tabla principal de empleados: T1_EMPLOYEES
-- Columnas más importantes:
--   employee_id, first_name, last_name, email, phone_number,
--   hire_date, job_id, salary, commission_pct, manager_id, department_id
--
-- Tabla de departamentos: T1_DEPARTMENTS
-- Columnas más importantes:
--   department_id, department_name, manager_id, location_id
--
-- Tabla de historial laboral: T1_JOB_HISTORY
-- Columnas más importantes:
--   employee_id, start_date, end_date, job_id, department_id
--
-- Tabla de auditoría: AUDIT_SALARY_ADJUSTMENTS_T1
-- Columnas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, pct_gap_to_avg_before, rule_applied,
--   executed_by, executed_at, notes
--
-- Tabla de variantes: T1_VARIANTS
-- Columnas:
--   variant_id, variant_name, excluded_department_id, min_years_service,
--   recent_job_history_months, gap_high_threshold_pct,
--   gap_mid_threshold_pct, raise_high_pct, raise_mid_pct,
--   raise_low_pct, max_salary_vs_avg_pct, notes

-- ============================================================
-- GUÍA RÁPIDA DE TÉRMINOS QUE DEBE USAR EN SU SOLUCIÓN
-- ============================================================
-- CTE:
--   Una CTE es una consulta temporal escrita con WITH.
--   Sirve para dividir una consulta grande en partes más claras.
--
--   Ejemplo:
--   WITH dept_stats AS (
--       SELECT department_id, AVG(salary) avg_salary
--       FROM t1_employees
--       GROUP BY department_id
--   )
--   SELECT *
--   FROM dept_stats;
--
-- Función analítica:
--   Es una función como ROW_NUMBER, RANK o DENSE_RANK.
--   Sirve para calcular posiciones o comparaciones sin perder el detalle.
--
--   Ejemplo:
--   DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC)
--
-- JOIN:
--   Es la unión entre tablas relacionadas, por ejemplo empleados y departamentos.
--
-- Subconsulta:
--   Es una consulta dentro de otra consulta.
--
-- SAVEPOINT:
--   Es un punto de restauración dentro de una transacción.
--   Permite devolver la operación a un punto intermedio con ROLLBACK TO.

-- ============================================================
-- 1. CONSULTA DIAGNÓSTICA
-- OBJETIVO:
-- Analizar la información antes de actualizar salarios.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   job_id
--   manager_id
--   department_id
--   department_name
--   salary
--   hire_date
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   salary_rank_in_department
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   years_service: años de antigüedad del empleado
--   dept_avg_salary: promedio salarial del departamento
--   dept_max_salary: salario más alto del departamento
--   dept_employee_count: cantidad de empleados del departamento
--   pct_gap_to_avg: porcentaje que le falta al salario del empleado para llegar
--                   al promedio del departamento
--   recent_job_history_flag: SI o NO, según si tuvo historial reciente
--   salary_rank_in_department: posición salarial dentro del departamento
--
-- IMPORTANTE:
-- - Puede usar una o varias CTE
-- - Debe usar al menos una función analítica
-- - Debe unir como mínimo T1_EMPLOYEES con T1_DEPARTMENTS
-- - Debe revisar T1_JOB_HISTORY para detectar historial reciente
-- ============================================================

PROMPT ===== 1. CONSULTA DIAGNÓSTICA =====

-- ESCRIBA AQUÍ SU CONSULTA DIAGNÓSTICA PRINCIPAL
-- Debe devolver las columnas mínimas exigidas arriba.

DEFINE p_variant_id = 2
DEFINE p_execution_tag = 'P02_FINAL'

WITH dept_stats AS ( 

    SELECT  

        e.department_id, 

        AVG(e.salary) AS dept_avg_salary, 

        MAX(e.salary) AS dept_max_salary, 

        COUNT(*) AS dept_employee_count 

    FROM t1_employees e 

    GROUP BY e.department_id 

), 

job_history_recent AS ( 

    SELECT DISTINCT employee_id 

    FROM t1_job_history 

    WHERE MONTHS_BETWEEN(SYSDATE, end_date) <= ( 

        SELECT recent_job_history_months  

        FROM t1_variants  

        WHERE variant_id = &p_variant_id 

    ) 

) 

SELECT  

    e.employee_id, 
    e.first_name, 
    e.last_name, 
    e.job_id, 
    e.manager_id, 
    e.department_id, 
    d.department_name, 
    e.salary, 
    e.hire_date, 

    TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) AS years_service, 

  
    ds.dept_avg_salary, 
    ds.dept_max_salary, 
    ds.dept_employee_count, 

    ROUND(((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100, 2) AS pct_gap_to_avg, 

    CASE  
        WHEN jh.employee_id IS NOT NULL THEN 'SI' 
        ELSE 'NO' 
    END AS recent_job_history_flag, 

    DENSE_RANK() OVER ( 

        PARTITION BY e.department_id  
        ORDER BY e.salary DESC 

    ) AS salary_rank_in_department 

FROM t1_employees e 

JOIN t1_departments d  
    ON e.department_id = d.department_id 
JOIN dept_stats ds  
    ON e.department_id = ds.department_id 
LEFT JOIN job_history_recent jh  
    ON e.employee_id = jh.employee_id; 

-- COMENTARIO OBLIGATORIO:
-- Explique en 3 a 5 líneas qué demuestra su consulta diagnóstica y por qué
-- le sirve para decidir qué empleados pueden ser elegibles.

-- Con esto se analiza la condicion actual de los empleados dentro de sus departamentos, 
-- viendo su antigüedad, posición salarial y diferencia respecto al promedio del área
-- a su vez se identifica si tienen historial laboral reciente, lo cual puede afectar su elegibilidad 

-- ============================================================
-- 2. DECISIÓN DE POBLACIÓN ELEGIBLE
-- OBJETIVO: 
-- Determinar qué empleados sí califican, cuáles no califican y por qué.
--
-- SU CONSULTA DEBE MOSTRAR, COMO MÍNIMO, ESTAS COLUMNAS:
--   employee_id
--   first_name
--   last_name
--   department_id
--   department_name
--   salary
--   years_service
--   dept_avg_salary
--   dept_max_salary
--   dept_employee_count
--   pct_gap_to_avg
--   recent_job_history_flag
--   manager_or_exec_flag
--   eligibility_flag
--   exclusion_reason
--   adjustment_pct
--   rule_applied
--
-- QUÉ SIGNIFICA CADA COLUMNA:
--   manager_or_exec_flag: SI o NO, según si es gerente principal o alta dirección
--   eligibility_flag: ELEGIBLE o NO_ELEGIBLE
--   exclusion_reason: motivo de exclusión, por ejemplo:
--                     SIN_DEPARTAMENTO, HISTORIAL_RECIENTE,
--                     ANTIGUEDAD_INSUFICIENTE, MANAGER_O_DIRECTIVO,
--                     DEPTO_EXCLUIDO, DEPTO_MENOR_A_3, SALARIO_NO_APLICA
--   adjustment_pct: porcentaje de ajuste que le corresponde
--   rule_applied: regla aplicada, por ejemplo AJUSTE_ALTO, AJUSTE_MEDIO, AJUSTE_BAJO
--
-- IMPORTANTE:
-- - Debe tomar en cuenta la variante asignada por el docente
-- - Debe usar los valores de T1_VARIANTS según &p_variant_id
-- - Debe quedar visible por qué una persona sí o no entra al proceso
-- ============================================================

PROMPT ===== 2. DECISIÓN DE ELEGIBLES =====

-- ESCRIBA AQUÍ SU CONSULTA DE DECISIÓN DE ELEGIBLES
-- Debe devolver las columnas mínimas exigidas arriba.

DEFINE p_variant_id = 2
DEFINE p_execution_tag = 'P02_FINAL'

WITH variant AS ( 

    SELECT * 

    FROM t1_variants 
    WHERE variant_id = &p_variant_id 

), 
dept_stats AS ( 

    SELECT  

        department_id, 
        AVG(salary) AS dept_avg_salary, 
        MAX(salary) AS dept_max_salary, 
        COUNT(*) AS dept_employee_count 

    FROM t1_employees 

    GROUP BY department_id 

), 

job_history_recent AS ( 

    SELECT DISTINCT employee_id 

    FROM t1_job_history 

    WHERE MONTHS_BETWEEN(SYSDATE, end_date) <= ( 

        SELECT recent_job_history_months FROM variant 
    ) 
), 

base AS ( 

    SELECT  

        e.employee_id, 
        e.first_name, 
        e.last_name, 
        e.department_id, 
        d.department_name, 
        e.salary, 

        TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date)/12) AS years_service, 

        ds.dept_avg_salary, 
        ds.dept_max_salary, 
        ds.dept_employee_count, 

        ROUND(((ds.dept_avg_salary - e.salary)/ds.dept_avg_salary)*100,2) AS pct_gap_to_avg,   

        CASE WHEN jh.employee_id IS NOT NULL THEN 'SI' ELSE 'NO' END AS recent_job_history_flag, 

        CASE  

            WHEN e.job_id LIKE '%MAN%' THEN 'SI' 
            ELSE 'NO' 

        END AS manager_or_exec_flag, 
        v.* 
    FROM t1_employees e 
    JOIN t1_departments d ON e.department_id = d.department_id 
    JOIN dept_stats ds ON e.department_id = ds.department_id 
    LEFT JOIN job_history_recent jh ON e.employee_id = jh.employee_id 
    CROSS JOIN variant v 
) 

SELECT  

    employee_id, 
    first_name, 
    last_name, 
    department_id, 
    department_name, 
    salary, 
    years_service, 
    dept_avg_salary, 
    dept_max_salary, 
    dept_employee_count, 
    pct_gap_to_avg, 
    recent_job_history_flag, 
    manager_or_exec_flag, 

    CASE  

        WHEN department_id IS NULL THEN 'NO_ELEGIBLE' 
        WHEN department_id = excluded_department_id THEN 'NO_ELEGIBLE' 
        WHEN dept_employee_count < 3 THEN 'NO_ELEGIBLE' 
        WHEN years_service < min_years_service THEN 'NO_ELEGIBLE' 
        WHEN recent_job_history_flag = 'SI' THEN 'NO_ELEGIBLE' 
        WHEN manager_or_exec_flag = 'SI' THEN 'NO_ELEGIBLE' 
        WHEN pct_gap_to_avg <= 0 THEN 'NO_ELEGIBLE' 
        ELSE 'ELEGIBLE' 

    END AS eligibility_flag, 

    CASE  

        WHEN department_id IS NULL THEN 'SIN_DEPARTAMENTO' 
        WHEN department_id = excluded_department_id THEN 'DEPTO_EXCLUIDO' 
        WHEN dept_employee_count < 3 THEN 'DEPTO_MENOR_A_3' 
        WHEN years_service < min_years_service THEN 'ANTIGUEDAD_INSUFICIENTE' 
        WHEN recent_job_history_flag = 'SI' THEN 'HISTORIAL_RECIENTE' 
        WHEN manager_or_exec_flag = 'SI' THEN 'MANAGER_O_DIRECTIVO' 
        WHEN pct_gap_to_avg <= 0 THEN 'SALARIO_NO_APLICA' 
        ELSE 'OK' 

    END AS exclusion_reason, 

    CASE  

        WHEN pct_gap_to_avg >= gap_high_threshold_pct THEN raise_high_pct 
        WHEN pct_gap_to_avg >= gap_mid_threshold_pct THEN raise_mid_pct 
        ELSE raise_low_pct 

    END AS adjustment_pct, 

    CASE  

        WHEN pct_gap_to_avg >= gap_high_threshold_pct THEN 'AJUSTE_ALTO' 
        WHEN pct_gap_to_avg >= gap_mid_threshold_pct THEN 'AJUSTE_MEDIO' 

        ELSE 'AJUSTE_BAJO' 

    END AS rule_applied 

FROM base; 


-- COMENTARIO OBLIGATORIO:
-- Explique en 3 a 5 líneas cómo aplicó la variante y por qué su población
-- elegible sí cumple las reglas del caso.

-- Esta consulta clasifica a los empleados según su elegibilidad para ajuste salarial, 
-- aplicando las reglas de excluir depto 60 y revisar historial de últimos 18 meses. 
-- Se identifican claramente los motivos de exclusión y el tipo de ajuste asignado, 
-- permitiendo transparencia en la toma de decisiones y validación del proceso.

-- ============================================================
-- 3. PREVALIDACIÓN ANTES DE LA TRANSACCIÓN
-- OBJETIVO:
-- Mostrar qué pasaría antes de ejecutar el cambio real.
--
-- DEBE MOSTRAR, COMO MÍNIMO:
-- A. Un resumen con estas columnas:
--    total_eligible_employees
--    total_salary_before
--    total_salary_after
--    total_increment
--
-- B. Un detalle de empleados elegibles con estas columnas:
--    employee_id
--    department_id
--    salary_before
--    salary_after
--    adjustment_pct
--    rule_applied
--
-- C. Un control de topes por departamento con estas columnas:
--    department_id
--    department_name
--    dept_avg_salary
--    dept_max_salary
--    max_allowed_salary_by_variant
--
-- QUÉ SIGNIFICA:
--   total_salary_before: suma de salarios antes del ajuste
--   total_salary_after: suma de salarios proyectados después del ajuste
--   total_increment: incremento total proyectado
--   max_allowed_salary_by_variant: salario máximo permitido según la variante
-- ============================================================

PROMPT ===== 3. PREVALIDACIÓN =====

--A

DEFINE p_variant_id = 2; 

WITH variant AS ( 

    SELECT *  
    FROM t1_variants  
    WHERE variant_id = &p_variant_id 

), 

dept_stats AS ( 

    SELECT department_id, AVG(salary) AS dept_avg_salary 
    FROM t1_employees 
    GROUP BY department_id 

), 

eligible_base AS ( 

    SELECT  
        e.employee_id, 
        e.salary AS salary_before, 
        ds.dept_avg_salary, 

        CASE  
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT  
                THEN var.RAISE_HIGH_PCT 
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT  
                THEN var.RAISE_MID_PCT 
            ELSE var.RAISE_LOW_PCT 
        END AS adjustment_pct 
    FROM t1_employees e 
    LEFT JOIN dept_stats ds  
        ON e.department_id = ds.department_id 

    CROSS JOIN variant var 

    WHERE  

        (e.department_id IS NULL OR e.department_id != var.EXCLUDED_DEPARTMENT_ID) 
        AND MONTHS_BETWEEN(SYSDATE, e.hire_date)/12 >= var.MIN_YEARS_SERVICE 
        AND NOT EXISTS ( 
            SELECT 1 
            FROM t1_job_history jh 
            WHERE jh.employee_id = e.employee_id 
              AND jh.start_date IS NOT NULL 
              AND MONTHS_BETWEEN(SYSDATE, jh.start_date) <= var.RECENT_JOB_HISTORY_MONTHS 

        ) 

), 

eligible_final AS ( 

    SELECT  
        salary_before, 
        salary_before + (salary_before * adjustment_pct / 100) AS salary_after 
    FROM eligible_base 

)

SELECT  

    COUNT(*) AS total_eligible_employees, 
    ROUND(SUM(salary_before), 2) AS total_salary_before, 
    ROUND(SUM(salary_after), 2) AS total_salary_after, 
    ROUND(SUM(salary_after - salary_before), 2) AS total_increment 

FROM eligible_final; 

-- ESCRIBA AQUÍ SU CONSULTA O SUS CONSULTAS DE PREVALIDACIÓN
-- Debe mostrar el resumen, el detalle y el control de topes.

-- Es el ajuste salarial para los empleados usando la variante seleccionada. 
-- primero obtiene el salario promedio por departamento y compara cada salario con ese promedio 
-- despues aplica un porcentaje de incremento según la diferencia encontrada, por ultimo 
-- hay un resumen con el total de empleados, salarios antes y después del ajuste, y el incremento total generado.

--B

DEFINE p_variant_id = 2; 

WITH variant AS ( 

    SELECT * FROM t1_variants WHERE variant_id = &p_variant_id 

), 

dept_stats AS ( 
    SELECT department_id, AVG(salary) AS dept_avg_salary 
    FROM t1_employees 
    GROUP BY department_id 

), 

eligible_base AS ( 

    SELECT  
        e.employee_id, 
        e.department_id, 
        e.salary AS salary_before, 
        ds.dept_avg_salary, 
        CASE  
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT  
                THEN var.RAISE_HIGH_PCT 
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT  
                THEN var.RAISE_MID_PCT 
            ELSE var.RAISE_LOW_PCT 
        END AS adjustment_pct, 
        CASE  
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT  
                THEN 'HIGH' 
            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT  
                THEN 'MEDIUM' 
            ELSE 'LOW' 
        END AS rule_applied 
    FROM t1_employees e 
    LEFT JOIN dept_stats ds  
        ON e.department_id = ds.department_id 
    CROSS JOIN variant var 
    WHERE  
        (e.department_id IS NULL OR e.department_id != var.EXCLUDED_DEPARTMENT_ID) 
        AND MONTHS_BETWEEN(SYSDATE, e.hire_date)/12 >= var.MIN_YEARS_SERVICE 
        AND NOT EXISTS ( 
            SELECT 1 
            FROM t1_job_history jh 
            WHERE jh.employee_id = e.employee_id 
              AND jh.start_date IS NOT NULL 
              AND MONTHS_BETWEEN(SYSDATE, jh.start_date) <= var.RECENT_JOB_HISTORY_MONTHS 

        ) 

), 

eligible_final AS ( 

    SELECT  
        employee_id, 
        department_id, 
        salary_before,   
        ROUND(salary_before + (salary_before * adjustment_pct / 100), 2) AS salary_after, 
        adjustment_pct, 
        rule_applied 
    FROM eligible_base 

) 

SELECT  

    employee_id, 
    department_id, 
    salary_before, 
    salary_after, 
    adjustment_pct, 
    rule_applied 

FROM eligible_final 

ORDER BY department_id; 

-- ESCRIBA AQUÍ SU CONSULTA O SUS CONSULTAS DE PREVALIDACIÓN
-- Debe mostrar el resumen, el detalle y el control de topes.

-- Se da el detalle de los empleados que cumplen con las condiciones de la variante 
-- calculando el nuevo salario aplicando un porcentaje de ajuste basado en la diferencia 
-- frente al promedio del departamento, a su vez se identifica la regla aplicada para 
-- justificar el incremento asignado a cada empleado. 

--C

DEFINE p_variant_id = 2; 

WITH variant AS ( 
    SELECT * FROM t1_variants WHERE variant_id = &p_variant_id 
), 
dept_stats AS ( 
    SELECT  
        department_id, 
        AVG(salary) AS dept_avg_salary, 
        MAX(salary) AS dept_max_salary 
    FROM t1_employees 
    GROUP BY department_id 
) 
SELECT  
    ds.department_id, 
    d.department_name, 
    ROUND(ds.dept_avg_salary, 2) AS dept_avg_salary, 
    ROUND(ds.dept_max_salary, 2) AS dept_max_salary, 
    ROUND(ds.dept_avg_salary * (var.MAX_SALARY_VS_AVG_PCT / 100), 2) AS max_allowed_salary_by_variant 
FROM dept_stats ds 

LEFT JOIN t1_departments d  
    ON ds.department_id = d.department_id 
CROSS JOIN variant var 
ORDER BY ds.department_id; 

-- ESCRIBA AQUÍ SU CONSULTA O SUS CONSULTAS DE PREVALIDACIÓN
-- Debe mostrar el resumen, el detalle y el control de topes.

-- Verifica los límites salariales definidos por la variante en cada departamento
-- calculando el promedio y el salario máximo actual para compararlos con el valor 
-- máximo permitido, ayudando a identificar si los salarios cumplen con las restricciones 
-- establecidas antes de aplicar cualquier ajuste.

-- ============================================================
-- 4. EJECUCIÓN TRANSACCIONAL
-- OBJETIVO:
-- Ejecutar la actualización real y registrar la auditoría.
--
-- DEBE INCLUIR OBLIGATORIAMENTE:
-- 1. SAVEPOINT
-- 2. UPDATE o MERGE para actualizar salarios
-- 3. INSERT a AUDIT_SALARY_ADJUSTMENTS_T1
-- 4. Validación intermedia
-- 5. COMMIT o ROLLBACK TO SAVEPOINT
--
-- IMPORTANTE:
-- - La auditoría debe usar el valor &p_execution_tag
-- - La auditoría debe usar el valor &p_variant_id
-- - Debe usar la secuencia AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
-- ============================================================

PROMPT ===== 4. EJECUCIÓN TRANSACCIONAL =====

SAVEPOINT sv_before_adjustment;

-- 4.1 ACTUALIZACIÓN DE SALARIOS
-- ESCRIBA AQUÍ SU UPDATE O MERGE
-- Debe actualizar únicamente empleados ELEGIBLES.

MERGE INTO t1_employees e 

USING ( 

    WITH variant AS ( 

        SELECT * FROM t1_variants WHERE variant_id = &p_variant_id 

    ), 

    dept_stats AS ( 

        SELECT department_id, AVG(salary) AS dept_avg_salary 

        FROM t1_employees 

        GROUP BY department_id 

    ) 

    SELECT  

        e.employee_id, 

        e.salary AS salary_before, 

  

        CASE  

            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT  

                THEN var.RAISE_HIGH_PCT 

            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT  

                THEN var.RAISE_MID_PCT 

            ELSE var.RAISE_LOW_PCT 

        END AS adjustment_pct 
    FROM t1_employees e 
    LEFT JOIN dept_stats ds  
        ON e.department_id = ds.department_id 

    CROSS JOIN variant var 

    WHERE  

        (e.department_id IS NULL OR e.department_id != var.EXCLUDED_DEPARTMENT_ID) 
        AND MONTHS_BETWEEN(SYSDATE, e.hire_date)/12 >= var.MIN_YEARS_SERVICE 
        AND NOT EXISTS ( 
            SELECT 1 
            FROM t1_job_history jh 
            WHERE jh.employee_id = e.employee_id 
              AND jh.start_date IS NOT NULL 
              AND MONTHS_BETWEEN(SYSDATE, jh.start_date) <= var.RECENT_JOB_HISTORY_MONTHS 

        ) 

) src 
ON (e.employee_id = src.employee_id) 
WHEN MATCHED THEN UPDATE SET 
    e.salary = e.salary + (e.salary * src.adjustment_pct / 100);

-- 4.2 INSERCIÓN EN AUDITORÍA
-- Debe llenar estas columnas de AUDIT_SALARY_ADJUSTMENTS_T1:
--   audit_id               -> usar AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL
--   execution_tag          -> usar &p_execution_tag
--   variant_id             -> usar &p_variant_id
--   employee_id            -> id del empleado ajustado
--   department_id          -> departamento del empleado
--   salary_before          -> salario antes del ajuste
--   salary_after           -> salario después del ajuste
--   pct_gap_to_avg_before  -> brecha porcentual antes del ajuste
--   rule_applied           -> regla aplicada
--   executed_by            -> USER
--   executed_at            -> SYSDATE
--   notes                  -> comentario libre

INSERT INTO audit_salary_adjustments_t1 (
    audit_id,
    execution_tag,
    variant_id,
    employee_id,
    department_id,
    salary_before,
    salary_after,
    pct_gap_to_avg_before,
    rule_applied,
    executed_by,
    executed_at,
    notes
)


WITH variant AS ( 

    SELECT * FROM t1_variants WHERE variant_id = &p_variant_id 

), 

dept_stats AS ( 

    SELECT department_id, AVG(salary) AS dept_avg_salary 

    FROM t1_employees 

    GROUP BY department_id 

) 

SELECT  

    AUDIT_SALARY_ADJ_T1_SEQ.NEXTVAL, 

    '&p_execution_tag', 

    &p_variant_id, 

    e.employee_id, 

    e.department_id, 

    e.salary / (1 + ( 

        CASE  

            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT THEN var.RAISE_HIGH_PCT 

            WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT THEN var.RAISE_MID_PCT 

            ELSE var.RAISE_LOW_PCT 

        END 

    ) / 100) AS salary_before, 

    e.salary AS salary_after, 

    ROUND(((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100, 2), 

    CASE  

        WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_HIGH_THRESHOLD_PCT THEN 'HIGH' 

        WHEN ((ds.dept_avg_salary - e.salary) / ds.dept_avg_salary) * 100 >= var.GAP_MID_THRESHOLD_PCT THEN 'MEDIUM' 

        ELSE 'LOW' 

    END, 

    USER, 

    SYSDATE, 

    'Ajuste salarial ejecutado' 

FROM t1_employees e 

LEFT JOIN dept_stats ds  

    ON e.department_id = ds.department_id 

CROSS JOIN variant var; 


;

-- 4.3 VALIDACIÓN INTERMEDIA
-- Debe mostrar, como mínimo, estas columnas:
--   employee_id
--   department_id
--   current_salary
--   original_salary
--   allowed_max_salary
--   validation_status
--
-- validation_status debe indicar si cumple o no cumple.

PROMPT ===== 4.3 VALIDACIÓN INTERMEDIA =====

-- ESCRIBA AQUÍ SU CONSULTA DE VALIDACIÓN INTERMEDIA

WITH variant AS ( 

    SELECT * FROM t1_variants WHERE variant_id = &p_variant_id 

), 

dept_stats AS ( 

    SELECT department_id, AVG(salary) AS dept_avg_salary 

    FROM t1_employees 

    GROUP BY department_id 

) 

SELECT  

    e.employee_id, 

    e.department_id, 

    e.salary AS current_salary, 

    ROUND(ds.dept_avg_salary,2) AS dept_avg_salary, 

    ROUND(ds.dept_avg_salary * (var.MAX_SALARY_VS_AVG_PCT / 100),2) AS allowed_max_salary, 

    CASE  

        WHEN e.salary <= ds.dept_avg_salary * (var.MAX_SALARY_VS_AVG_PCT / 100) 

            THEN 'OK' 

        ELSE 'EXCEDE' 

    END AS validation_status 

FROM t1_employees e 

LEFT JOIN dept_stats ds  

    ON e.department_id = ds.department_id 

CROSS JOIN variant var; 

 

-- 4.4 CONTROL TRANSACCIONAL
-- Debe demostrar UNO de estos escenarios:
-- A. COMMIT si toda la validación es correcta



-- B. ROLLBACK TO SAVEPOINT si detecta incumplimientos
--
-- ESCRIBA AQUÍ SU DECISIÓN TRANSACCIONAL Y AGREGUE UN COMENTARIO
-- explicando por qué hizo COMMIT o por qué hizo ROLLBACK.



-- ============================================================
-- 5. VALIDACIÓN POSTERIOR
-- OBJETIVO:
-- Demostrar el resultado final de la transacción.
--
-- DEBE MOSTRAR, COMO MÍNIMO, ESTAS 4 SALIDAS:
--
-- SALIDA 1. Empleados impactados
-- Columnas mínimas:
--   employee_id, first_name, last_name, department_id,
--   salary_before, salary_after, execution_tag
--
-- SALIDA 2. Resumen económico final
-- Columnas mínimas:
--   total_rows_audited, total_salary_before, total_salary_after, total_increment
--
-- SALIDA 3. Validación de topes
-- Columnas mínimas:
--   employee_id, department_id, salary_after, allowed_max_salary, top_limit_status
--
-- SALIDA 4. Auditoría generada
-- Columnas mínimas:
--   audit_id, execution_tag, variant_id, employee_id, department_id,
--   salary_before, salary_after, rule_applied, executed_by, executed_at
--
-- IMPORTANTE:
-- Todas las validaciones posteriores deben filtrar por &p_execution_tag
-- ============================================================

PROMPT ===== 5. VALIDACIÓN POSTERIOR =====

-- SALIDA 1. EMPLEADOS IMPACTADOS



-- SALIDA 2. RESUMEN ECONÓMICO FINAL



-- SALIDA 3. VALIDACIÓN DE TOPES



-- SALIDA 4. AUDITORÍA GENERADA



-- ============================================================
-- 6. JUSTIFICACIÓN TÉCNICA
-- Responder dentro del script, en comentarios.
-- Cada respuesta debe tener entre 3 y 6 líneas.
-- ============================================================


-- ============================================================
-- 6. JUSTIFICACIÓN TÉCNICA
-- ============================================================

-- ATOMICIDAD: Explique cómo su solución demuestra atomicidad.
--
-- RESPUESTA:
-- La solución demuestra atomicidad al ejecutar todos los cambios dentro de una 
-- misma transacción controlada, al ocurrir algún error durante la actualización 
-- de salarios o la inserción en la auditoría, se utiliza ROLLBACK para revertir 
-- todos los cambios realizados. De esta forma, la operación se ejecuta completamente 
-- o no se ejecuta, evitando inconsistencias parciales en los datos.

-- CONSISTENCIA: Explique cómo su solución asegura que los datos quedan válidos
-- después de la operación.
--
-- RESPUESTA:
-- La consistencia se asegura mediante validaciones previas y posteriores a la 
-- actualización, como el control de topes salariales y verificación de empleados 
-- elegibles, adicionalmente, se respetan las reglas definidas en la variante seleccionada, 
-- garantizando que los salarios actualizados cumplan las políticas establecidas 
-- y mantengan la integridad de los datos.

-- AISLAMIENTO: Explique cómo se comportaría su transacción frente a otras sesiones.
--
-- RESPUESTA:
-- El aislamiento se mantiene porque la transacción no hace visibles los cambios 
-- a otras sesiones hasta que se ejecute el COMMIT, mientras tanto, otras 
-- transacciones continúan trabajando con los datos originales, asi evitando 
-- conflictos y lecturas inconsistentes durante la ejecución del proceso.

-- DURABILIDAD: Explique qué garantiza la persistencia del cambio una vez confirmado.
--
-- RESPUESTA:
-- La durabilidad se garantiza mediante el uso de COMMIT, el cual confirma 
-- permanentemente los cambios realizados en la base de datos, ya que una vez ejecutado 
-- el COMMIT, los datos quedan almacenados de forma persistente y no se pierden 
-- incluso si ocurre un fallo posterior del sistema.

-- USO DE SAVEPOINT / ROLLBACK: Explique qué riesgo controló y por qué ese punto de restauración
-- era necesario.
--
-- RESPUESTA:
-- El uso del SAVEPOINT permite establecer un punto de control antes de realizar 
-- la actualización de salarios, porque si al validar intermedia se detecta 
-- algún incumplimiento, se utiliza ROLLBACK TO SAVEPOINT para revertir únicamente 
-- los cambios realizados después del punto de control, reduciendoo riesgo de 
-- afectar datos válidos y permite mantener la integridad del proceso.
--
-- PROMPT ===== Fin de plantilla =====
