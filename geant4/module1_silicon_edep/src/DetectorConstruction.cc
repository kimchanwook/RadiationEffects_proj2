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

  // World volume. It only needs to be comfortably larger than the silicon target.
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

  fScoringVolume = siliconLogical;

  // Visualization attributes.
  worldLogical->SetVisAttributes(G4VisAttributes::GetInvisible());

  auto siliconVis = new G4VisAttributes(G4Colour(0.0, 0.2, 1.0, 0.35));
  siliconVis->SetForceSolid(true);
  siliconVis->SetForceAuxEdgeVisible(true);
  siliconLogical->SetVisAttributes(siliconVis);

  return worldPhysical;
}
