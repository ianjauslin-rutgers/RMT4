import Mathlib
import RMT4.pintegral
import RMT4.LocallyConstant

open Topology Filter Metric TopologicalSpace Set

def holo_covering (_ : HasLocalPrimitiveOn U f) := U × ℂ

def LocalPrimitiveOn.map (Λ : LocalPrimitiveOn U f) (z : U) (v : ℂ) : U → holo_covering ⟨Λ⟩ :=
  λ w => (w, v + (Λ.F z w - Λ.F z z))

namespace holo_covering

def proj {h : HasLocalPrimitiveOn U f} : holo_covering h → U := λ w => w.1

lemma lemma1 (Λ : LocalPrimitiveOn U f) (z : U) (f : ℂ → ℂ) (w : U) :
  proj (Λ.map z u w) = w := rfl

def is_a_nhd (Λ : LocalPrimitiveOn U f) (z : holo_covering ⟨Λ⟩)
  (s : Set (holo_covering ⟨Λ⟩)) : Prop := ∃ t ∈ 𝓝 z.1, Λ.map z.1 z.2 '' t ⊆ s

def nhd (Λ : LocalPrimitiveOn U f) (z : holo_covering ⟨Λ⟩) : Filter (holo_covering ⟨Λ⟩) :=
  Filter.map (Λ.map z.1 z.2) (𝓝 z.1)

lemma mem_nhd (Λ : LocalPrimitiveOn U f) (z : holo_covering ⟨Λ⟩) (s : Set (holo_covering ⟨Λ⟩)) :
    s ∈ nhd Λ z ↔ ∃ t ∈ 𝓝 z.1, Λ.map z.1 z.2 '' t ⊆ s := by
  sorry

lemma mem_nhd' (Λ : LocalPrimitiveOn U f) (z : holo_covering ⟨Λ⟩) (s : Set (holo_covering ⟨Λ⟩)) :
    s ∈ nhd Λ z ↔ ∀ᶠ w in 𝓝 z.1, Λ.map z.1 z.2 w ∈ s := by
  -- simp only [eventually_iff, LocalPrimitiveOn.map]
  -- -- simp only [← exists_mem_subset_iff (s := {w | Λ.map z.1 z.2 w ∈ s})]
  -- convert mem_nhd Λ z s
  -- simp
  -- rfl
  sorry

instance : TopologicalSpace (holo_covering h) := TopologicalSpace.mkOfNhds (nhd h.some)

def p (h : HasLocalPrimitiveOn U f) : holo_covering h → U := λ z => z.1

lemma pure_le_nhd (h : HasLocalPrimitiveOn U f) : pure ≤ nhd (h.some) := by
  intro a
  rw [pure_le_iff]
  intro s hs
  obtain ⟨t, h1, h2⟩ := mem_map_iff_exists_image.1 hs
  apply h2
  simp
  refine ⟨a.1, a.1.prop, mem_of_mem_nhds h1, by { simp [LocalPrimitiveOn.map] }⟩

theorem extend (h : HasLocalPrimitiveOn U f) (a : holo_covering h) :
    ∀ S ∈ nhd h.some a, ∃ T ∈ nhd h.some a, T ⊆ S ∧ ∀ a' ∈ T, S ∈ nhd h.some a' := by
  intro S hS
  obtain ⟨t, h1, h2⟩ := (mem_nhd h.some a S).1 hS
  let s := proj '' S
  let s' := U.restrict (h.some.S a.1)
  let S' := h.some.map a.1 a.2 '' s'
  have hS' : S' ∈ nhd h.some a := by
    rw [mem_nhd]
    refine ⟨s', ?_⟩
    sorry
  refine ⟨S ∩ S', Filter.inter_mem hS hS', inter_subset_left _ _, ?_⟩
  rintro b ⟨hb1, hb2⟩
  rw [mem_nhd]

  use U.restrict (h.some.S b.1) ∩ proj '' (S ∩ S')
  refine ⟨?_, ?_⟩
  · sorry
  · sorry

lemma discreteTopology (h : HasLocalPrimitiveOn U f) (z : U) :
    DiscreteTopology ↑(p h ⁻¹' {z}) := by
  let Λ := h.some
  simp [discreteTopology_iff_singleton_mem_nhds, nhds_mkOfNhds, nhds_induced, p]
  rintro ⟨z, u⟩ rfl
  rw [nhds_mkOfNhds]
  · refine ⟨Λ.map z u '' U.restrict (Λ.S z), ?_, ?_⟩
    · apply image_mem_map
      simp only [nhds_induced]
      exact ⟨_, Λ.nhd z, by rfl⟩
    · rintro ⟨⟨a₁, ha₁⟩, a₂⟩ rfl
      simp [LocalPrimitiveOn.map]
      rintro z hz _ h2
      obtain ⟨h3, h4⟩ := Prod.ext_iff.1 h2
      simp at h3 h4
      simp [LocalPrimitiveOn.map, h3] at h4
      rw [← h4]
  · refine pure_le_nhd h
  · apply extend

  -- intro ⟨⟨x₁, x₂⟩, hx⟩
  -- simp [p] at hx ; subst hx
  -- simp [nhds_induced, mem_nhds h]
  -- obtain ⟨Λ⟩ := id h
  -- refine ⟨basic_nhd Λ x₁ x₂, is_nhd h Λ _, ?_⟩
  -- rintro ⟨w₁, w₂⟩ rfl hb
  -- simp [basic_nhd] at hb
  -- rcases hb with ⟨a, ha, _, h2⟩
  -- refine Prod.ext rfl ?_
  -- rw [← h2]
  -- rw [Prod.ext_iff] at h2
  -- simp at h2
  -- simp p, ← h2.1]

-- theorem main (h : HasLocalPrimitiveOn U f) : IsCoveringMap (p h) := by
--   intro z
--   refine ⟨discreteTopology h z, ?_⟩
--   sorry


-- def basic_nhd (Λ : LocalPrimitiveOn U f) (z : U) (u : ℂ) : Set (holo_covering ⟨Λ⟩) :=
--   Λ.map z u '' U.restrict (Λ.S z)

-- lemma lemma3 (Λ : LocalPrimitiveOn U f) (z : U) (u : ℂ) (w) :
--     w ∈ basic_nhd Λ z u ↔ w.1.1 ∈ Λ.S z ∧ w.2 = u + (Λ.F z w.1 - Λ.F z z) := by
--   simp [basic_nhd]
--   constructor
--   · rintro ⟨a, ha, h1, h2⟩
--     obtain ⟨h3, h4⟩ := Prod.ext_iff.1 h2
--     simp [Subtype.ext_iff_val] at h3 h4
--     subst a
--     exact ⟨h1, h4.symm⟩
--   · rintro ⟨h1, h2⟩
--     refine ⟨w.1, w.1.prop, h1, ?_⟩
--     rw [Prod.ext_iff]
--     exact ⟨rfl, h2.symm⟩

-- lemma lemma1 (Λ : LocalPrimitiveOn U f) (z : U) (u : ℂ) :
--     ∀ z' ∈ basic_nhd Λ z u, z'.1.1 ∈ Λ.S z := by
--   rintro z' hz'
--   exact ((lemma3 Λ z u z').1 hz').1

-- def is_nhd_of (h : HasLocalPrimitiveOn U f) (z : holo_covering h) (s : Set (holo_covering h)) : Prop :=
--   ∃ F : ℂ → ℂ, ∀ᶠ w in 𝓝 z.1, HasDerivAt F (f w) w ∧
--     ∀ hw : w ∈ U, (⟨w, hw⟩, z.2 + (F w - F z.1)) ∈ s

-- lemma is_nhd (h : HasLocalPrimitiveOn U f) (Λ : LocalPrimitiveOn U f) (z : holo_covering h) :
--     is_nhd_of h z (basic_nhd Λ z.1 z.2) := by
--   simp [is_nhd_of]
--   use Λ.F z.1
--   constructor
--   · exact eventually_of_mem (Λ.nhd z.1) (Λ.der z.1)
--   · apply eventually_of_mem (Λ.nhd z.1)
--     intro x hx1 hx2
--     simpa [basic_nhd] using ⟨x, ⟨hx2, hx1⟩, rfl, rfl⟩

-- def nhd (h : HasLocalPrimitiveOn U f) (z : holo_covering h) :
--     Filter (holo_covering h) where
--   sets := { s | is_nhd_of h z s }
--   univ_sets := by
--     obtain ⟨F, hF⟩ := HasLocalPrimitiveOn.iff.1 h z.1 z.1.prop
--     use F
--     filter_upwards [hF] with w h using ⟨h, by simp⟩
--   sets_of_superset := by
--     rintro s1 s2 ⟨F, hF⟩ h2
--     use F
--     filter_upwards [hF] with w ⟨hw1, hw2⟩ using ⟨hw1, λ hw => h2 (hw2 hw)⟩
--   inter_sets := by
--     rintro s1 s2 ⟨F1, hF1⟩ ⟨F2, hF2⟩
--     use F1
--     filter_upwards [hF1, hF2, eventuallyEq_of_hasDeriv (eventually_and.1 hF1).1 (eventually_and.1 hF2).1]
--       with w ⟨e1, e2⟩ ⟨_, e4⟩ e5 using ⟨e1, λ hw => ⟨e2 hw, e5 ▸ e4 hw⟩⟩


-- lemma nhd_of_nhd (h : HasLocalPrimitiveOn U f) (a : holo_covering h) :
--     ∀ s ∈ nhd h a, ∃ t ∈ nhd h a, t ⊆ s ∧ ∀ a' ∈ t, s ∈ nhd h a' := by
--   obtain ⟨Λ⟩ := h
--   intro s hs
--   let s' := basic_nhd Λ a.1 a.2
--   have hs' : s' ∈ nhd ⟨Λ⟩ a := is_nhd ⟨Λ⟩ Λ a
--   have l1 := (nhd ⟨Λ⟩ a).inter_mem hs hs'
--   refine ⟨s ∩ s', l1, inter_subset_left s s', λ b ⟨hb, hb'⟩ => ?_⟩
--   simp [nhd, is_nhd_of]
--   have := (lemma3 Λ a.1 a.2 b).1 hb'
--   have l2 : Λ.S a.1 ∈ 𝓝 ↑b.1 := by
--     · apply (Λ.opn a.1).mem_nhds
--       simp only at hb'
--       apply lemma1
--       exact hb'
--   refine ⟨Λ.F a.1, ?_, ?_⟩
--   · apply eventually_of_mem (U := Λ.S a.1)
--     · exact l2
--     · exact Λ.der a.1
--   · apply eventually_of_mem (U := Λ.S a.1 ∩ Λ.S b.1)
--     · apply Filter.inter_mem l2
--       exact Λ.nhd b.1
--     · intro x ⟨hx1, hx2⟩ hx'
--       simp [this.2]
--       ring_nf


--       sorry

-- -- instance : TopologicalSpace (holo_covering h) := TopologicalSpace.mkOfNhds (nhd h)


-- lemma mem_nhds (h : HasLocalPrimitiveOn U f) (z : holo_covering h) (s : Set (holo_covering h)) :
--     s ∈ 𝓝 z ↔ is_nhd_of h z s := by
--   rw [nhds_mkOfNhds (nhd h) z (pure_le_nhd h) (nhd_of_nhd h)] ; rfl

-- lemma discreteTopology {U : Set ℂ} {f : ℂ → ℂ} (h : HasLocalPrimitiveOn U f) (z : U) :
--     DiscreteTopology ↑(p h ⁻¹' {z}) := by
--   simp only [discreteTopology_iff_singleton_mem_nhds]
--   intro ⟨⟨x₁, x₂⟩, hx⟩
--   simp [p] at hx ; subst hx
--   simp [nhds_induced, mem_nhds h]
--   obtain ⟨Λ⟩ := id h
--   refine ⟨basic_nhd Λ x₁ x₂, is_nhd h Λ _, ?_⟩
--   rintro ⟨w₁, w₂⟩ rfl hb
--   simp [basic_nhd] at hb
--   rcases hb with ⟨a, ha, _, h2⟩
--   refine Prod.ext rfl ?_
--   rw [← h2]
--   rw [Prod.ext_iff] at h2
--   simp at h2
--   simp [lift, p, ← h2.1]

-- theorem main (h : HasLocalPrimitiveOn U f) : IsCoveringMap (p h) := by
--   intro z
--   refine ⟨discreteTopology h z, ?_⟩
--   sorry

end holo_covering