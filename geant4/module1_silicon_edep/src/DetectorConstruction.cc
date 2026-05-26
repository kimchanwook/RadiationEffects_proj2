#include "DetectorConstruction.hh"

#include "G4Box.hh"
#include "G4LogicalVolume.hh"
#include "G4Material.hh"
#include "G4NistManager.hh"
#include "G4PVPlacement.hh"
#include "G4SystemOfUnits.hh"
#include "G4VisAttributes.hh"
#include "G4Colour.hh"

G4VPhysicalVolume* DetectorConstruction::Construct()
{
  auto nist = G4NistManager::Instance();

  // Materials.
  auto worldMaterial = nist->FindOrBuildMaterial("G4_Galactic");
  auto silicon       = nist->FindOrBuildMaterial("G4_Si");
  auto tungsten      = nist->FindOrBuildMaterial("G4_W");

  // World volume. It only needs to be comfortably larger than the silicon target
  // and the top tungsten shield.
  const G4double worldHalfX = 0.5 * mm;
  const G4double worldHalfY = 0.5 * mm;
  const G4double worldHalfZ = 0.5 * mm;

  auto worldSolid = new G4Box("WorldSolid", worldHalfX, worldHalfY, worldHalfZ);
  auto worldLogical = new G4LogicalVolume(worldSolid, worldMaterial, "WorldLV");
  auto worldPhysical = new G4PVPlacement(
      nullptr,
      G4ThreeVector(),
      worldLogical,
      "WorldPV",
      nullptr,
      false,
      0,
      true);

  // Module 1 silicon target geometry:
  // full size = 20 um in x, 20 um in y, 50 um in z.
  // Geant4 G4Box takes half-lengths.
  const G4double siliconHalfX = 10.0 * um;
  const G4double siliconHalfY = 10.0 * um;
  const G4double siliconHalfZ = 25.0 * um;

  auto siliconSolid = new G4Box("SiliconSolid", siliconHalfX, siliconHalfY, siliconHalfZ);
  auto siliconLogical = new G4LogicalVolume(siliconSolid, silicon, "SiliconLV");

  new G4PVPlacement(
      nullptr,
      G4ThreeVector(0.0, 0.0, 0.0),
      siliconLogical,
      "SiliconPV",
      worldLogical,
      false,
      0,
      true);

  // --------------------------------------------------------------------------
  // Top shielding layer: tungsten cap directly above the silicon device.
  //
  // Silicon is centered at z = 0 and has half-thickness 25 um, so its top
  // surface is at z = +25 um. A tungsten shield of thickness t_W is centered at
  //
  //   z_W = siliconHalfZ + 0.5*t_W.
  //
  // For the initial case below, t_W = 1 um, so the shield occupies
  // z = +25 um to +26 um and sits directly on top of the silicon.
  // --------------------------------------------------------------------------
  const G4double tungstenThickness = 1.0 * um;
  //const G4double tungstenThickness = 2.0 * um;
  //const G4double tungstenThickness = 3.0 * um;
  //const G4double tungstenThickness = 4.0 * um;
  //const G4double tungstenThickness = 5.0 * um;
  const G4double tungstenHalfX = siliconHalfX;
  const G4double tungstenHalfY = siliconHalfY;
  const G4double tungstenHalfZ = 0.5 * tungstenThickness;
  const G4double tungstenCenterZ = siliconHalfZ + tungstenHalfZ;

  auto tungstenSolid = new G4Box("TungstenShieldSolid",
                                 tungstenHalfX,
                                 tungstenHalfY,
                                 tungstenHalfZ);

  auto tungstenLogical = new G4LogicalVolume(tungstenSolid,
                                             tungsten,
                                             "TungstenShieldLV");

  new G4PVPlacement(
      nullptr,
      G4ThreeVector(0.0, 0.0, tungstenCenterZ),
      tungstenLogical,
      "TungstenShieldPV",
      worldLogical,
      false,
      0,
      true);

  // Score only the energy deposited in the silicon target. The tungsten layer is
  // passive shielding in this first study.
  fScoringVolume = siliconLogical;

  // Visualization attributes.
  worldLogical->SetVisAttributes(G4VisAttributes::GetInvisible());

  auto siliconVis = new G4VisAttributes(G4Colour(0.0, 0.2, 1.0, 0.35));
  siliconVis->SetForceSolid(true);
  siliconVis->SetForceAuxEdgeVisible(true);
  siliconLogical->SetVisAttributes(siliconVis);

  auto tungstenVis = new G4VisAttributes(G4Colour(0.45, 0.45, 0.45, 0.75));
  tungstenVis->SetForceSolid(true);
  tungstenVis->SetForceAuxEdgeVisible(true);
  tungstenLogical->SetVisAttributes(tungstenVis);

  return worldPhysical;
}
