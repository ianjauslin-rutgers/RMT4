import Mathlib

set_option autoImplicit false

open Topology Filter Metric TopologicalSpace Set Subtype

variable {ι α β : Type} [TopologicalSpace α] {i₁ i₂ i j : ι} {a : α} {b : β} {s t : Set α}

structure Bunch (ι α β : Type) [TopologicalSpace α] where
  F : ι → α → β
  S : ι → Set α
  cov (z : α × β) : ∃ i, z.1 ∈ S i ∧ F i z.1 = z.2
  cmp i j : IsOpen { a ∈ S i ∩ S j | F i a = F j a }

instance : CoeFun (Bunch ι α β) (λ _ => ι → α → β) := ⟨Bunch.F⟩

namespace Bunch

lemma opn (B : Bunch ι α β) (i : ι) : IsOpen (B.S i) := by simpa using B.cmp i i

def space (_ : Bunch ι α β) := α × β

def idx (B : Bunch ι α β) (z : B.space) : Set ι := { i | z.1 ∈ B.S i ∧ B i z.1 = z.2 }

def tile (B : Bunch ι α β) (i : ι) (s : Set α) : Set B.space := (λ x => (x, B i x)) '' s

variable {B : Bunch ι α β} {s s₁ s₂ : Set B.space} {z : B.space}

lemma S_mem_nhd (hi : i ∈ B.idx z) : B.S i ∈ 𝓝 z.1 := B.opn i |>.mem_nhds hi.1

lemma tile_mono {s t : Set α} (h : s ⊆ t) : B.tile i s ⊆ B.tile i t := image_subset _ h

lemma tile_congr {s : Set α} (h : EqOn (B i) (B j) s) : B.tile i s = B.tile j s :=
  image_congr (λ x hx => by rw [h hx])

lemma subset_iff_forall (a : Set α) (b : Set β) (f : α → β) : f '' a ⊆ b ↔ ∀ x ∈ a, f x ∈ b := by
  rw [image_subset_iff] ; rfl

lemma eventuallyEq (hi : a ∈ B.S i) (hj : a ∈ B.S j) (h : B i a = B j a) : ∀ᶠ b in 𝓝 a, B i b = B j b :=
  (eventually_and.1 <| (B.cmp i j).mem_nhds ⟨⟨hi, hj⟩, h⟩).2

lemma tile_inter {s₁ s₂ : Set α} (hi₁ : i₁ ∈ B.idx z) (hi₂ : i₂ ∈ B.idx z) (hi : i ∈ B.idx z)
    (h₁ : s₁ ∈ 𝓝 z.1) (h₂ : s₂ ∈ 𝓝 z.1) :
    ∃ s ∈ 𝓝 z.1, B.tile i s ⊆ B.tile i₁ s₁ ∩ B.tile i₂ s₂ := by
  suffices : ∀ᶠ b in 𝓝 z.1, (b, B i b) ∈ B.tile i₁ s₁ ∩ B.tile i₂ s₂
  · simpa only [eventually_iff_exists_mem, ← subset_iff_forall] using this
  have l1 := eventuallyEq hi₁.1 hi.1 (hi₁.2.trans hi.2.symm)
  have l2 := eventuallyEq hi₂.1 hi.1 (hi₂.2.trans hi.2.symm)
  filter_upwards [h₁, h₂, l1, l2] with b e1 e2 e3 e4
  exact ⟨⟨b, e1, by simp only [e3]⟩, ⟨b, e2, by simp only [e4]⟩⟩

def reaches (B : Bunch ι α β) (is : ι × Set α) (z : B.space) := is.1 ∈ B.idx z ∧ is.2 ∈ 𝓝 z.1

lemma isBasis (z : B.space) : IsBasis (λ is => B.reaches is z) (λ is => B.tile is.1 is.2) where
  nonempty := by
    obtain ⟨i, hi⟩ := B.cov z
    refine ⟨⟨i, univ⟩, hi, univ_mem⟩
  inter := by
    rintro i j ⟨hi1, hi2⟩ ⟨hj1, hj2⟩
    obtain ⟨s, hs1, hs2⟩ := tile_inter hi1 hj1 hi1 hi2 hj2
    refine ⟨⟨i.1, s⟩, ⟨⟨hi1, hs1⟩, hs2⟩⟩

def nhd (z : B.space) : Filter B.space := (isBasis z).filter

instance : TopologicalSpace B.space := TopologicalSpace.mkOfNhds nhd

lemma mem_nhd : s ∈ nhd z ↔ ∃ i ∈ B.idx z, ∃ v ∈ 𝓝 z.1, B.tile i v ⊆ s := by
  simp [nhd, (isBasis z).mem_filter_iff, reaches, and_assoc]

theorem eventually_apply_mem {f : α → β} {t : Set β} :
    (∀ᶠ x in 𝓝 a, f x ∈ t) ↔ (∃ s ∈ 𝓝 a, s ⊆ f ⁻¹' t) :=
  eventually_iff_exists_mem

theorem eventually_mem_iff_tile : (∀ᶠ b in 𝓝 a, (b, B j b) ∈ s) ↔ (∃ v ∈ 𝓝 a, tile B j v ⊆ s) := by
  simp [tile, ← eventually_apply_mem]

lemma tile_mem_nhd {s : Set α} (hi : i ∈ B.idx z) (hs : s ∈ 𝓝 z.1) : B.tile i s ∈ nhd z := by
  simpa only [nhd, IsBasis.mem_filter_iff] using ⟨(i, s), ⟨hi, hs⟩, subset_rfl⟩

lemma mem_nhd_open (h : s ∈ nhd z) : ∃ i ∈ B.idx z, ∃ v ∈ 𝓝 z.1, IsOpen v ∧ B.tile i v ⊆ s := by
  obtain ⟨i, hi1, t, hi3, hi4⟩ := mem_nhd.1 h
  obtain ⟨s', ⟨h1, h2⟩, h3⟩ := nhds_basis_opens' z.1 |>.mem_iff.1 hi3
  exact ⟨i, hi1, s', h1, h2, tile_mono h3 |>.trans hi4⟩

theorem pure_le (z : B.space) : pure z ≤ nhd z := by
  intro s hs
  obtain ⟨i, hi1, hi2, hi3, hi4⟩ := mem_nhd.1 hs
  exact hi4 ⟨z.1, mem_of_mem_nhds hi3, by simp [hi1.2]⟩

theorem nhd_is_nhd (a : space B) (s : Set (space B)) (hs : s ∈ nhd a) :
    ∃ t ∈ nhd a, t ⊆ s ∧ ∀ b ∈ t, s ∈ nhd b := by
  obtain ⟨i, hi1, s₀, hi2, hi3, hi4⟩ := mem_nhd_open hs
  refine ⟨B.tile i (s₀ ∩ B.S i), ?_, ?_, ?_⟩
  · exact tile_mem_nhd hi1 <| inter_mem hi2 <| S_mem_nhd hi1
  · exact tile_mono (inter_subset_left _ _) |>.trans hi4
  · rintro b ⟨c, hb1, rfl⟩
    refine mem_of_superset ?_ hi4
    refine tile_mem_nhd ⟨?_, rfl⟩ ?_
    · exact inter_subset_right _ _ hb1
    · exact hi3.mem_nhds <| inter_subset_left _ _ hb1

lemma nhds_eq_nhd : 𝓝 z = nhd z := nhds_mkOfNhds _ _ pure_le nhd_is_nhd

lemma mem_nhds_tfae : List.TFAE [
      s ∈ 𝓝 z,
      s ∈ nhd z,
      ∃ i ∈ B.idx z, ∀ᶠ a in 𝓝 z.1, (a, B i a) ∈ s,
      ∃ i ∈ B.idx z, ∃ t ∈ 𝓝 z.1, B.tile i t ⊆ s
    ] := by
  tfae_have 1 ↔ 2 ; simp [nhds_eq_nhd]
  tfae_have 2 ↔ 4 ; exact mem_nhd
  tfae_have 3 ↔ 4 ; simp [eventually_mem_iff_tile]
  tfae_finish

lemma mem_nhds_iff : s ∈ 𝓝 z ↔ ∃ i ∈ B.idx z, ∀ᶠ a in 𝓝 z.1, (a, B i a) ∈ s :=
  mem_nhds_tfae.out 0 2

def p (B : Bunch ι α β) (z : B.space) : α := z.1

lemma discreteTopology : DiscreteTopology (B.p ⁻¹' {a}) := by
  simp [discreteTopology_iff_singleton_mem_nhds, nhds_induced]
  rintro ⟨z₁, z₂⟩ rfl
  dsimp [p]
  obtain ⟨i, h1, h2⟩ := B.cov (z₁, z₂)
  have h3 := S_mem_nhd ⟨h1, h2⟩
  refine ⟨B.tile i <| B.S i, ?_, ?_⟩
  · rw [nhds_eq_nhd]
    exact tile_mem_nhd ⟨h1, h2⟩ h3
  · rintro ⟨x₁, x₂⟩ rfl ⟨u, _, hu2⟩
    obtain ⟨rfl, rfl⟩ := Prod.ext_iff.1 hu2
    simp_all only

end Bunch