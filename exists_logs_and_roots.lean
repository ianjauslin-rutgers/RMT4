-- -- import isolated_zeros
-- import analysis.complex.cauchy_integral
-- import to_mathlib
-- import mul_as_cont_lin_map

-- noncomputable theory

-- open_locale topological_space

-- lemma convex.exists_primitive_of_holom {U : set ℂ}
--   (U_conv : convex ℝ U) (U_open : is_open U)
--   {f : ℂ → ℂ} (f_hol : differentiable_on ℂ f U) {w : ℂ} (w_in_U : w ∈ U) :
--   ∃ (F : ℂ → ℂ), F w = 0 ∧ differentiable_on ℂ F U ∧ ∀ z ∈ U, deriv F z = f z :=
-- begin
--   sorry,
-- end

-- lemma differentiable_on_deriv_complex_domain {U : set ℂ} (U_open : is_open U)
--   {f : ℂ → ℂ} (f_hol : differentiable_on ℂ f U) :
--   differentiable_on ℂ (λ z, deriv f z) U :=
-- begin
--   sorry,
-- end

-- /-- If a complex function has zero derivative at every point of a convex domain,
-- then it is a constant on this set. -/
-- theorem _root_.convex.is_const_of_deriv_eq_zero {U : set ℂ}
--   (U_conv : convex ℝ U) (U_open : is_open U) {f : ℂ → ℂ} (f_hol : differentiable_on ℂ f U)
--   (df_zero : ∀ z ∈ U, deriv f z = 0) {w₁ w₂ : ℂ} (hw₁ : w₁ ∈ U) (hw₂ : w₂ ∈ U) :
--   f w₁ = f w₂ :=
-- begin
--   refine convex.is_const_of_fderiv_within_eq_zero U_conv f_hol _ hw₁ hw₂,
--   intros z z_in_U,
--   have := (differentiable_on_complex_domain_has_fderiv_at U_open f_hol z_in_U).has_fderiv_at,
--   simp only [df_zero z z_in_U, complex.as_continuous_linear_map_zero] at this,
--   rw fderiv_within_eq_fderiv _ _,
--   { exact this.fderiv, },
--   { exact is_open.unique_diff_within_at U_open z_in_U, },
--   { exact f_hol.differentiable_at (U_open.mem_nhds z_in_U), },
-- end

-- lemma convex.exists_log_of_nonvanish
--   {U : set ℂ} (U_conv : convex ℝ U) (U_open : is_open U)
--   {f : ℂ → ℂ} (f_hol : differentiable_on ℂ f U) (f_nonvanish : ∀ z ∈ U, f z ≠ 0) :
--   ∃ (log_f : ℂ → ℂ), differentiable_on ℂ log_f U
--                      ∧ ∀ z ∈ U, complex.exp (log_f z) = f z :=
-- begin
--   by_cases hU : U = ∅,
--   { use 0, simp [hU, differentiable_on_empty], },
--   rcases set.nonempty_iff_ne_empty.2 hU with ⟨z₀, z₀_in_U⟩,
--   set df_over_f := λ z, (deriv f z) / (f z) with df_over_f_def,
--   have df_over_f_hol : differentiable_on ℂ df_over_f U,
--   { apply differentiable_on.div _ f_hol f_nonvanish,
--     exact differentiable_on_deriv_complex_domain U_open f_hol, },
--   have key := U_conv.exists_primitive_of_holom U_open df_over_f_hol z₀_in_U,
--   rcases key with ⟨g, ⟨g_z₀_eq, g_hol, hg⟩⟩,
--   set logf := λ z, g z + complex.log (f z₀) with logf_def,
--   refine ⟨logf, differentiable_on.add_const g_hol _, _⟩,
--   have exp_logf_eq_C_exp_g : ∀ z, complex.exp (logf z) = (complex.exp (g z)) * (f z₀),
--   { intro z,
--     simp_rw [logf_def, complex.exp_add],
--     apply mul_eq_mul_left_iff.mpr (or.inl _),
--     exact complex.exp_log (f_nonvanish z₀ z₀_in_U), },
--   simp_rw exp_logf_eq_C_exp_g,
--   --
--   -- g' = f' / f
--   -- D (f * exp(-g)) = f' * exp(-g) + f * (-f' / f) * exp(-g) = 0 * exp(-g) = 0
--   --
--   have R_diffble : differentiable_on ℂ (λ z, (f z) * complex.exp (-g z)) U,
--     from differentiable_on.mul f_hol (differentiable_on.cexp g_hol.neg),
--   have key : ∀ w ∈ U, deriv (λ z, (f z) * complex.exp (-g z)) w = 0,
--   { intros w w_in_U,
--     have d_neg_g := (g_hol.neg.differentiable_at (U_open.mem_nhds w_in_U)),
--     rw deriv_mul (f_hol.differentiable_at (U_open.mem_nhds w_in_U)),
--     { rw [deriv_cexp d_neg_g, mul_comm (complex.exp _), ←mul_assoc],
--       dsimp,
--       rw ←add_mul,
--       refine mul_eq_zero.mpr (or.inl _),
--       simp only [deriv.neg', mul_neg, hg w w_in_U, df_over_f_def],
--       rw [mul_div_cancel'],
--       { ring, },
--       { exact f_nonvanish w w_in_U, }, },
--     exact differentiable_at.cexp d_neg_g, },
--   intros z z_in_U,
--   have := U_conv.is_const_of_deriv_eq_zero U_open R_diffble key z_in_U z₀_in_U,
--   simp only [g_z₀_eq, neg_zero, complex.exp_zero, mul_one] at this,
--   rw [←this, ←mul_assoc, mul_comm, ←mul_assoc, ←complex.exp_add],
--   simp,
-- end

-- lemma convex.exists_nth_root_of_nonvanish
--   {U : set ℂ} (U_conv : convex ℝ U) (U_open : is_open U)
--   {f : ℂ → ℂ} (f_hol : differentiable_on ℂ f U)
--   (f_nonvanish : ∀ z ∈ U, f z ≠ 0) {n : ℕ} (n_pos : 0 < n) :
--   ∃ (root_f : ℂ → ℂ), differentiable_on ℂ root_f U ∧ ∀ z ∈ U, (root_f z)^n = f z :=
-- begin
--   rcases U_conv.exists_log_of_nonvanish U_open f_hol f_nonvanish with ⟨logf, logf_hol, exp_logf_eq⟩,
--   set rootf := λ z, complex.exp (logf z / n) with rootf_def,
--   refine ⟨rootf, _, _⟩,
--   { exact complex.differentiable_exp.comp_differentiable_on
--           (differentiable_on.div_const logf_hol), },
--   { intros z z_in_ball,
--     simp [rootf_def, ←complex.exp_nat_mul _ n,
--           mul_div_cancel' _ (show (n : ℂ) ≠ 0, by { norm_cast, exact n_pos.ne.symm, }),
--           exp_logf_eq z z_in_ball], },
-- end

-- lemma convex.exists_sqrt_of_nonvanish
--   {U : set ℂ} (U_conv : convex ℝ U) (U_open : is_open U)
--   {f : ℂ → ℂ} {z₀ : ℂ} {r : ℝ} (f_hol : differentiable_on ℂ f U) (f_nonvanish : ∀ z ∈ U, f z ≠ 0) :
--   ∃ (sqrt_f : ℂ → ℂ), differentiable_on ℂ sqrt_f U ∧ ∀ z ∈ U, (sqrt_f z)^2 = f z :=
-- U_conv.exists_nth_root_of_nonvanish U_open f_hol f_nonvanish zero_lt_two
