-- Report grouping only: employee/payroll/attendance records stay unchanged.
CREATE TABLE IF NOT EXISTS app_private.salary_report_branch_assignments (
  employee_id text NOT NULL REFERENCES public.employees(employee_id) ON UPDATE CASCADE ON DELETE CASCADE,
  period date NOT NULL CHECK (period = date_trunc('month', period)::date),
  branch_id text NOT NULL REFERENCES public.branches(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  assigned_by text NOT NULL,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (employee_id, period)
);
REVOKE ALL ON app_private.salary_report_branch_assignments FROM PUBLIC;
