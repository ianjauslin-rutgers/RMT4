import Mathlib.Analysis.Convex.Normed
import Mathlib.Analysis.Convex.Segment
import Mathlib.Topology.Covering
import Mathlib.Topology.LocallyConstant.Basic
import RMT4.Glue

set_option autoImplicit false
set_option pp.proofs.withType false

open Set Topology Metric unitInterval Filter

section helpers

variable {E X : Type*} [TopologicalSpace E] [TopologicalSpace X] {f : E → X} {γ : C(I, X)} {A : E}
  {t t₁ t₂ : I}

lemma isClopen_iff_nhds {α : Type*} [TopologicalSpace α] {s : Set α} :
    IsClopen s ↔ ∀ a, ∀ᶠ b in 𝓝 a, b ∈ s ↔ a ∈ s where
  mp h a := by
    by_cases h3 : a ∈ s
    · simpa [h3] using h.1.mem_nhds h3
    · simpa only [h3, iff_false] using h.2.isOpen_compl.mem_nhds h3
  mpr h := by
    constructor
    · simpa [isOpen_iff_mem_nhds] using λ a ha => by simpa [ha] using h a
    · exact ⟨by simpa [isOpen_iff_mem_nhds] using λ a ha => by simpa only [ha, iff_false] using h a⟩

abbrev II (t : I) : Set ℝ := Icc 0 t
@[simp] lemma II_zero : II 0 = {0} := by simp [II]
lemma mem_II_zero {t : ℝ} : t ∈ II 0 ↔ t = 0 := by simp [II]
@[simp] lemma II_one : II 1 = I := rfl
lemma self_mem_II : ↑t ∈ II t := by simp [II, t.prop.1]
instance : Zero (II t) := by exact ⟨0, le_rfl, t.prop.1⟩
instance : CoeOut (II t) I := ⟨λ s => ⟨↑s, s.prop.1, s.prop.2.trans t.prop.2⟩⟩

def reachable (f : E → X) (γ : C(I, X)) (A : E) (t : I) : Prop :=
  ∃ Γ : C(II t, E), Γ 0 = A ∧ ∀ s, f (Γ s) = γ s

lemma reachable_zero (hγ : γ 0 = f A) : reachable f γ A 0 :=
  ⟨⟨λ _ => A, continuous_const⟩, rfl, λ ⟨s, hs⟩ => by simp [mem_II_zero.1 hs, hγ]⟩

lemma reachable_extend {T : Trivialization (f ⁻¹' {γ t}) f} (h : MapsTo γ (uIcc t₁ t₂) T.baseSet) :
    reachable f γ A t₁ → reachable f γ A t₂ := by
  rintro ⟨Γ, h1, h2⟩
  set tt₁ : II t₁ := ⟨t₁, self_mem_II⟩
  let δ : C(uIcc (t₁ : ℝ) (t₂ : ℝ), E) := by
    let ι (u : uIcc (t₁:ℝ) (t₂:ℝ)) : uIcc t₁ t₂ :=
      ⟨⟨u, (le_inf t₁.2.1 t₂.2.1).trans u.2.1, u.2.2.trans (sup_le t₁.2.2 t₂.2.2)⟩, u.2⟩
    refine ⟨λ s => T.invFun ⟨γ (ι s).1, (T (Γ tt₁)).2⟩, ?_⟩
    refine T.continuous_invFun.comp_continuous (by continuity) (λ s => ?_)
    simpa only [T.target_eq, mem_prod, mem_univ, and_true] using h (ι s).2
  refine ⟨Γ.trans' t₁.prop.1 δ ?_, ?_, λ s => ?_⟩
  · have l1 : f (Γ tt₁) = γ t₁ := h2 tt₁
    have k1 : Γ tt₁ ∈ T.source := by simpa [T.source_eq, l1] using h left_mem_uIcc
    simpa [← l1, ← T.proj_toFun _ k1] using (T.left_inv' k1).symm
  · exact h1 ▸ ContinuousMap.trans'_left t₁.2.1 t₂.2.1 _
  · by_cases hh : (s : ℝ) ≤ t₁
    · simp [ContinuousMap.trans', glue_uIcc, hh, h2 ⟨s, s.2.1, hh⟩]
    · simp only [ContinuousMap.trans', glue_uIcc, ContinuousMap.coe_mk, hh, dite_false]
      have : γ s ∈ T.baseSet := h ⟨inf_le_left.trans (not_le.1 hh).le, s.2.2.trans le_sup_right⟩
      refine (T.proj_toFun _ (T.map_target' <| by simpa [T.target_eq] using this)).symm.trans ?_
      exact congr_arg Prod.fst (T.right_inv' <| by simpa [T.target_eq] using this)

lemma reachable_nhds_iff (hf : IsCoveringMap f) :
    ∀ᶠ t' in 𝓝 t, reachable f γ A t' ↔ reachable f γ A t := by
  obtain ⟨_, T, h4⟩ := hf (γ t)
  have l2 : γ ⁻¹' T.baseSet ∈ 𝓝 t :=
    γ.continuous_toFun.continuousAt.preimage_mem_nhds <| T.open_baseSet.mem_nhds h4
  simp only [Filter.Eventually, Metric.mem_nhds_iff] at l2 ⊢
  obtain ⟨ε, hε, l3⟩ := l2
  refine ⟨ε, hε, λ u hu => ?_⟩
  have l4 : uIcc t u ⊆ ball t ε := by
    suffices uIcc t.1 u.1 ⊆ ball t.1 ε by intro v ; apply this
    simpa only [segment_eq_uIcc] using (convex_ball t.1 ε).segment_subset (mem_ball_self hε) hu
  have l5 : MapsTo γ (uIcc t u) T.baseSet := λ v hv => l3 (l4 hv)
  exact ⟨reachable_extend <| uIcc_comm t u ▸ l5, reachable_extend l5⟩

end helpers

variable {E X : Type*} [TopologicalSpace E] [TopologicalSpace X] {f : E → X} {γ : C(I, X)} {A : E}

theorem lift (hf : IsCoveringMap f) (hγ : γ 0 = f A) : ∃ Γ : C(I, E), Γ 0 = A ∧ f ∘ Γ = γ := by
  have l1 : Set.Nonempty {t | reachable f γ A t} := ⟨0, reachable_zero hγ⟩
  have l2 : IsClopen {t | reachable f γ A t} := isClopen_iff_nhds.2 <| λ t => reachable_nhds_iff hf
  let ⟨Γ, h1, h2⟩ := ((isClopen_iff.1 l2).resolve_left <| Nonempty.ne_empty l1).symm ▸ mem_univ 1
  exact ⟨Γ, h1, funext h2⟩

--

section Iic

open ContinuousMap

variable {t t₁ t₂ : I}

instance : Zero (Iic t) := ⟨0, nonneg'⟩
instance : ZeroLEOneClass I := ⟨nonneg'⟩

def reachable' (f : E → X) (γ : C(I, X)) (A : E) (t : I) : Prop :=
  ∃ Γ : C(Iic t, E), Γ 0 = A ∧ ∀ s, f (Γ s) = γ s

lemma reachable'_zero (hγ : γ 0 = f A) : reachable' f γ A 0 := by
  refine ⟨⟨λ _ => A, continuous_const⟩, rfl, ?_⟩
  intro ⟨s, (hs : s ≤ 0)⟩ ; simp [le_antisymm hs s.2.1, hγ]

lemma reachable'_extend {T : Trivialization (f ⁻¹' {γ t}) f} (h : MapsTo γ (uIcc t₁ t₂) T.baseSet) :
    reachable' f γ A t₁ → reachable' f γ A t₂ := by
  rintro ⟨Γ, rfl, h2⟩
  let T₁ : Iic t₁ := ⟨t₁, mem_Iic.2 le_rfl⟩
  let δ : C(uIcc t₁ t₂, E) := ⟨λ s => T.invFun ⟨γ s, (T (Γ T₁)).2⟩,
    T.continuous_invFun.comp_continuous (by continuity) (λ t => by simp [T.target_eq, h t.2])⟩
  have l1 : f (Γ T₁) = γ t₁ := h2 T₁
  have l2 : Γ T₁ ∈ T.source := by simpa only [T.source_eq, mem_preimage, l1] using h left_mem_uIcc
  refine ⟨trans_Iic Γ δ ?_, trans_Iic_of_le nonneg', λ s => ?_⟩
  · simpa only [ContinuousMap.coe_mk, ← l1, ← T.proj_toFun _ l2] using (T.left_inv' l2).symm
  · by_cases H : s ≤ t₁ <;> simp only [trans_Iic, glue_Iic, ContinuousMap.coe_mk, H, dite_true, h2]
    have l5 : γ s ∈ T.baseSet := h ⟨inf_le_left.trans (not_le.1 H).le, le_trans s.2 le_sup_right⟩
    have l6 {z} : (γ s, z) ∈ T.target := T.mem_target.2 l5
    exact (T.proj_toFun _ (T.map_target' l6)).symm.trans <| congr_arg Prod.fst (T.right_inv' l6)

lemma reachable'_nhds_iff (hf : IsCoveringMap f) :
    ∀ᶠ t' in 𝓝 t, reachable' f γ A t' ↔ reachable' f γ A t := by
  obtain ⟨_, T, h4⟩ := hf (γ t)
  have l2 := γ.continuous_toFun.continuousAt.preimage_mem_nhds <| T.open_baseSet.mem_nhds h4
  simp only [Filter.Eventually, Metric.mem_nhds_iff] at l2 ⊢
  obtain ⟨ε, hε, l3⟩ := l2
  refine ⟨ε, hε, λ u hu => ?_⟩
  have : segment ℝ t.1 u.1 ⊆ ball t.1 ε := (convex_ball t.1 ε).segment_subset (mem_ball_self hε) hu
  have l5 : uIcc t.1 u.1 ⊆ ball t.1 ε := by rwa [← segment_eq_uIcc]
  have l6 : MapsTo γ (uIcc t u) T.baseSet := λ v hv => l3 (l5 hv)
  exact ⟨reachable'_extend <| uIcc_comm t u ▸ l6, reachable'_extend l6⟩

theorem lift' (hf : IsCoveringMap f) (hγ : γ 0 = f A) : ∃ Γ : C(I, E), Γ 0 = A ∧ f ∘ Γ = γ := by
  have l1 : Set.Nonempty {t | reachable' f γ A t} := ⟨0, reachable'_zero hγ⟩
  have l2 : IsClopen {t | reachable' f γ A t} := isClopen_iff_nhds.2 (λ t => reachable'_nhds_iff hf)
  let ⟨Γ, h1, h2⟩ := ((isClopen_iff.1 l2).resolve_left <| Nonempty.ne_empty l1).symm ▸ mem_univ 1
  refine ⟨⟨IicExtend Γ, Γ.2.Iic_extend'⟩, by simpa [IicExtend, projIic] using h1, funext (λs => ?_)⟩
  simp [IicExtend, projIic, s.2.2] ; convert h2 ⟨s, s.2.2⟩ ; simpa using s.2.2

variable {Γ Γ₁ Γ₂ : C(I, E)}

lemma key {x : X} (T : Trivialization (f ⁻¹' {x}) f) [ht : DiscreteTopology (f ⁻¹' {x})]
    (h : Γ t ∈ T.source) : ∀ᶠ s in 𝓝 t, T (Γ s) = (f (Γ s), (T (Γ t)).2) := by
  have l1 : T.source ∈ 𝓝 (Γ t) := T.open_source.mem_nhds h
  have l2 := (T.continuous_toFun.continuousAt l1).comp Γ.continuous.continuousAt
  have l3 : Tendsto (λ s => (T (Γ s)).2) (𝓝 t) _ := (continuousAt_snd.comp l2).tendsto
  have l4 : ∀ᶠ s in 𝓝 t, Γ s ∈ T.source := Γ.continuous.continuousAt l1
  have l5 : ∀ᶠ s in 𝓝 t, (T (Γ s)).2 ∈ {(T (Γ t)).2} := l3 (by simp)
  filter_upwards [l4, l5] with s r4 r5 using Prod.ext (T.proj_toFun _ r4) r5

lemma key2 {x : X} (T : Trivialization (f ⁻¹' {x}) f) [ht : DiscreteTopology (f ⁻¹' {x})]
    (h : Γ t ∈ T.source) : ∀ᶠ s in 𝓝 t, Γ s = T.invFun (f (Γ s), (T (Γ t)).2) := by
  have l1 := Γ.continuous.continuousAt <| T.open_source.mem_nhds h
  filter_upwards [key T h, l1] with s r1 r2 using
    T.left_inv r2 |>.symm.trans <| congr_arg T.invFun r1

lemma locally_eq (hf : IsCoveringMap f) (h1 : Γ₁ t = Γ₂ t) (h2 : f ∘ Γ₁ = f ∘ Γ₂) :
    Γ₁ =ᶠ[𝓝 t] Γ₂ := by
  obtain ⟨l1, T, l2⟩ := hf (f (Γ₁ t))
  rw [← T.mem_source] at l2
  filter_upwards [key2 T l2, key2 (Γ := Γ₂) T (h1 ▸ l2)] with s r2 r3
  rw [r2, r3] ; simp [h1, show f (Γ₁ s) = f (Γ₂ s) from congr_fun h2 s]

lemma locally_eq_iff (hf : IsCoveringMap f) (h2 : f ∘ Γ₁ = f ∘ Γ₂) :
    ∀ᶠ s in 𝓝 t, Γ₁ s = Γ₂ s ↔ Γ₁ t = Γ₂ t := by
  obtain ⟨l1, T, l2⟩ := hf (f (Γ₁ t))
  have l3 : f (Γ₂ t) ∈ T.baseSet := by simp [← show f (Γ₁ t) = f (Γ₂ t) from congr_fun h2 t, l2]
  rw [← T.mem_source] at l2 l3
  filter_upwards [key2 T l2, key2 T l3, key T l2, key T l3] with s r2 r3 r4 r5
  constructor <;> intro h
  · suffices T (Γ₁ t) = T (Γ₂ t) by rw [← T.left_inv' l2, ← T.left_inv' l3] ; congr 1
    apply Prod.ext
    · exact T.proj_toFun _ l2 |>.trans (congr_fun h2 t |>.trans (T.proj_toFun _ l3 |>.symm))
    · simpa using congr_arg Prod.snd (show (_, _) = (_, _) from (h ▸ r4).symm.trans r5)
  · rw [r2, r3] ; simp [h, show f (Γ₁ s) = f (Γ₂ s) from congr_fun h2 s]

theorem lift_unique (hf : IsCoveringMap f) {Γ₁ Γ₂ : C(I, E)} (h0 : Γ₁ 0 = Γ₂ 0)
    (h : f ∘ Γ₁ = f ∘ Γ₂) : Γ₁ = Γ₂ := by
  have l1 : IsClopen {t | Γ₁ t = Γ₂ t} := isClopen_iff_nhds.2 <| λ t => locally_eq_iff hf h
  have l3 := isClopen_iff.1 l1 |>.resolve_left <| Nonempty.ne_empty ⟨0, h0⟩
  ext t ; exact eq_univ_iff_forall.1 l3 t

end Iic
