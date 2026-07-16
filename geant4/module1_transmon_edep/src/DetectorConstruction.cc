#include "DetectorConstruction.hh"

#include "GeometryComponent.hh"

#include "G4Box.hh"
#include "G4Colour.hh"
#include "G4LogicalVolume.hh"
#include "G4Material.hh"
#include "G4MultiUnion.hh"
#include "G4NistManager.hh"
#include "G4PVPlacement.hh"
#include "G4RotationMatrix.hh"
#include "G4SystemOfUnits.hh"
#include "G4ThreeVector.hh"
#include "G4Torus.hh"
#include "G4Transform3D.hh"
#include "G4UserLimits.hh"
#include "G4VisAttributes.hh"

#include <array>

namespace
{
constexpr G4bool kCheckOverlaps = true;

// Geant4 boxes take half lengths. All z coordinates are defined with the chip
// top surface at z = 0 and the substrate extending toward negative z.
const G4double kChipX = 5.0 * mm;
const G4double kChipY = 3.0 * mm;
const G4double kChipZ = 0.5 * mm;
const G4double kMetalThickness = 100.0 * nm;
const G4double kMetalCenterZ = 0.5 * kMetalThickness;

G4Transform3D Translation(const G4ThreeVector& translation)
{
  return G4Transform3D(G4RotationMatrix(), translation);
}

void AddBoxNode(G4MultiUnion* multiUnion,
                const G4String& name,
                G4double fullX,
                G4double fullY,
                G4double fullZ,
                const G4ThreeVector& center)
{
  auto* box = new G4Box(name, 0.5 * fullX, 0.5 * fullY, 0.5 * fullZ);
  multiUnion->AddNode(*box, Translation(center));
}

G4LogicalVolume* PlaceBox(const G4String& solidName,
                          const G4String& logicalName,
                          const G4String& physicalName,
                          G4double fullX,
                          G4double fullY,
                          G4double fullZ,
                          const G4ThreeVector& center,
                          G4Material* material,
                          G4LogicalVolume* mother,
                          G4int copyNumber = 0)
{
  auto* solid = new G4Box(solidName, 0.5 * fullX, 0.5 * fullY, 0.5 * fullZ);
  auto* logical = new G4LogicalVolume(solid, material, logicalName);
  new G4PVPlacement(nullptr,
                    center,
                    logical,
                    physicalName,
                    mother,
                    false,
                    copyNumber,
                    kCheckOverlaps);
  return logical;
}
}

void DetectorConstruction::RegisterScoringVolume(G4LogicalVolume* logicalVolume,
                                                  const G4int componentID)
{
  fComponentByLogicalVolume[logicalVolume] = componentID;
}

G4int DetectorConstruction::GetComponentID(const G4LogicalVolume* logicalVolume) const
{
  const auto iter = fComponentByLogicalVolume.find(logicalVolume);
  return iter == fComponentByLogicalVolume.end() ? -1 : iter->second;
}

void DetectorConstruction::SetVisualization(G4LogicalVolume* logicalVolume,
                                            const G4double red,
                                            const G4double green,
                                            const G4double blue,
                                            const G4double alpha) const
{
  auto* vis = new G4VisAttributes(G4Colour(red, green, blue, alpha));
  vis->SetForceSolid(true);
  vis->SetForceAuxEdgeVisible(true);
  logicalVolume->SetVisAttributes(vis);
}

G4VPhysicalVolume* DetectorConstruction::Construct()
{
  fComponentByLogicalVolume.clear();

  auto* nist = G4NistManager::Instance();

  auto* vacuum = nist->FindOrBuildMaterial("G4_Galactic");
  auto* silicon = nist->FindOrBuildMaterial("G4_Si");
  auto* aluminum = nist->FindOrBuildMaterial("G4_Al");
  auto* aluminumOxide = nist->FindOrBuildMaterial("G4_ALUMINUM_OXIDE");
  auto* copper = nist->FindOrBuildMaterial("G4_Cu");
  auto* gold = nist->FindOrBuildMaterial("G4_Au");
  auto* palladium = nist->FindOrBuildMaterial("G4_Pd");

  // --------------------------------------------------------------------------
  // World
  // --------------------------------------------------------------------------
  auto* worldSolid = new G4Box("WorldSolid", 4.0 * mm, 2.5 * mm, 2.0 * mm);
  auto* worldLogical = new G4LogicalVolume(worldSolid, vacuum, "WorldLV");
  auto* worldPhysical = new G4PVPlacement(nullptr,
                                           G4ThreeVector(),
                                           worldLogical,
                                           "WorldPV",
                                           nullptr,
                                           false,
                                           0,
                                           kCheckOverlaps);
  worldLogical->SetVisAttributes(G4VisAttributes::GetInvisible());

  // --------------------------------------------------------------------------
  // Substrate: high-resistivity silicon proxy, 5 mm x 3 mm x 0.5 mm.
  // To use sapphire instead, replace G4_Si with G4_ALUMINUM_OXIDE above.
  // --------------------------------------------------------------------------
  auto* substrateLogical = PlaceBox("SubstrateSolid",
                                    "SubstrateLV",
                                    "SubstratePV",
                                    kChipX,
                                    kChipY,
                                    kChipZ,
                                    G4ThreeVector(0.0, 0.0, -0.5 * kChipZ),
                                    silicon,
                                    worldLogical);
  substrateLogical->SetUserLimits(new G4UserLimits(10.0 * um));
  RegisterScoringVolume(substrateLogical,
                        static_cast<G4int>(GeometryComponent::Substrate));
  SetVisualization(substrateLogical, 0.55, 0.72, 0.90, 0.42);

  // --------------------------------------------------------------------------
  // Central transmon: two 600 um x 300 um pads, 8 um-wide leads, one effective
  // 1 um x 1 um Al/AlOx/Al junction. G4MultiUnion permits the documented
  // 10.5 um pad/lead overlap without creating overlapping physical volumes.
  // --------------------------------------------------------------------------
  auto* leftNodeSolid = new G4MultiUnion("LeftTransmonNodeSolid");
  AddBoxNode(leftNodeSolid,
             "LeftPadNode",
             600.0 * um,
             300.0 * um,
             kMetalThickness,
             G4ThreeVector(-330.0 * um, 0.0, kMetalCenterZ));
  AddBoxNode(leftNodeSolid,
             "LeftLeadNode",
             40.0 * um,
             8.0 * um,
             kMetalThickness,
             G4ThreeVector(-20.5 * um, 0.0, kMetalCenterZ));
  leftNodeSolid->Voxelize();
  auto* leftNodeLogical = new G4LogicalVolume(leftNodeSolid,
                                               aluminum,
                                               "LeftTransmonNodeLV");
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    leftNodeLogical,
                    "LeftTransmonNodePV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  leftNodeLogical->SetUserLimits(new G4UserLimits(25.0 * nm));
  RegisterScoringVolume(leftNodeLogical,
                        static_cast<G4int>(GeometryComponent::LeftTransmonNode));
  SetVisualization(leftNodeLogical, 1.00, 0.65, 0.00, 0.95);

  auto* rightNodeSolid = new G4MultiUnion("RightTransmonNodeSolid");
  AddBoxNode(rightNodeSolid,
             "RightPadNode",
             600.0 * um,
             300.0 * um,
             kMetalThickness,
             G4ThreeVector(+330.0 * um, 0.0, kMetalCenterZ));
  AddBoxNode(rightNodeSolid,
             "RightLeadNode",
             40.0 * um,
             8.0 * um,
             kMetalThickness,
             G4ThreeVector(+20.5 * um, 0.0, kMetalCenterZ));
  rightNodeSolid->Voxelize();
  auto* rightNodeLogical = new G4LogicalVolume(rightNodeSolid,
                                                aluminum,
                                                "RightTransmonNodeLV");
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    rightNodeLogical,
                    "RightTransmonNodePV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  rightNodeLogical->SetUserLimits(new G4UserLimits(25.0 * nm));
  RegisterScoringVolume(rightNodeLogical,
                        static_cast<G4int>(GeometryComponent::RightTransmonNode));
  SetVisualization(rightNodeLogical, 1.00, 0.65, 0.00, 0.95);

  // The effective JJ area is 1 um x 1 um. The 2 nm AlOx barrier is represented
  // as a lateral slab between two Al electrodes so the left-to-right circuit
  // topology is explicit and no volumes overlap.
  const G4double jjBarrierX = 2.0 * nm;
  const G4double jjElectrodeX = 0.5 * (1.0 * um - jjBarrierX);

  auto* jjLeftLogical = PlaceBox("JJLeftElectrodeSolid",
                                 "JJLeftElectrodeLV",
                                 "JJLeftElectrodePV",
                                 jjElectrodeX,
                                 1.0 * um,
                                 kMetalThickness,
                                 G4ThreeVector(-0.5 * (jjBarrierX + jjElectrodeX),
                                               0.0,
                                               kMetalCenterZ),
                                 aluminum,
                                 worldLogical);
  jjLeftLogical->SetUserLimits(new G4UserLimits(10.0 * nm));
  RegisterScoringVolume(jjLeftLogical,
                        static_cast<G4int>(GeometryComponent::JJLeftElectrode));
  SetVisualization(jjLeftLogical, 0.92, 0.25, 0.08, 1.0);

  auto* jjBarrierLogical = PlaceBox("JJBarrierSolid",
                                    "JJBarrierLV",
                                    "JJBarrierPV",
                                    jjBarrierX,
                                    1.0 * um,
                                    kMetalThickness,
                                    G4ThreeVector(0.0, 0.0, kMetalCenterZ),
                                    aluminumOxide,
                                    worldLogical);
  jjBarrierLogical->SetUserLimits(new G4UserLimits(0.5 * nm));
  RegisterScoringVolume(jjBarrierLogical,
                        static_cast<G4int>(GeometryComponent::JJBarrier));
  SetVisualization(jjBarrierLogical, 0.82, 0.00, 0.00, 1.0);

  auto* jjRightLogical = PlaceBox("JJRightElectrodeSolid",
                                  "JJRightElectrodeLV",
                                  "JJRightElectrodePV",
                                  jjElectrodeX,
                                  1.0 * um,
                                  kMetalThickness,
                                  G4ThreeVector(+0.5 * (jjBarrierX + jjElectrodeX),
                                                0.0,
                                                kMetalCenterZ),
                                  aluminum,
                                  worldLogical);
  jjRightLogical->SetUserLimits(new G4UserLimits(10.0 * nm));
  RegisterScoringVolume(jjRightLogical,
                        static_cast<G4int>(GeometryComponent::JJRightElectrode));
  SetVisualization(jjRightLogical, 0.92, 0.25, 0.08, 1.0);

  // --------------------------------------------------------------------------
  // Normal-metal quasiparticle trap: 100 um x 10 um x 80 nm on the right pad.
  // The baseline Cu/Pd/Au stack is split into 40/20/20 nm layers.
  // --------------------------------------------------------------------------
  const G4double trapX = 100.0 * um;
  const G4double trapY = 10.0 * um;
  const G4double trapCenterX = 500.0 * um;
  const G4double trapCenterY = 90.0 * um;

  auto* trapCuLogical = PlaceBox("TrapCuSolid",
                                 "TrapCuLV",
                                 "TrapCuPV",
                                 trapX,
                                 trapY,
                                 40.0 * nm,
                                 G4ThreeVector(trapCenterX,
                                               trapCenterY,
                                               kMetalThickness + 20.0 * nm),
                                 copper,
                                 worldLogical);
  auto* trapPdLogical = PlaceBox("TrapPdSolid",
                                 "TrapPdLV",
                                 "TrapPdPV",
                                 trapX,
                                 trapY,
                                 20.0 * nm,
                                 G4ThreeVector(trapCenterX,
                                               trapCenterY,
                                               kMetalThickness + 50.0 * nm),
                                 palladium,
                                 worldLogical);
  auto* trapAuLogical = PlaceBox("TrapAuSolid",
                                 "TrapAuLV",
                                 "TrapAuPV",
                                 trapX,
                                 trapY,
                                 20.0 * nm,
                                 G4ThreeVector(trapCenterX,
                                               trapCenterY,
                                               kMetalThickness + 70.0 * nm),
                                 gold,
                                 worldLogical);
  for (auto* logical : {trapCuLogical, trapPdLogical, trapAuLogical}) {
    logical->SetUserLimits(new G4UserLimits(10.0 * nm));
    RegisterScoringVolume(logical,
                          static_cast<G4int>(GeometryComponent::NormalMetalTrap));
  }
  SetVisualization(trapCuLogical, 0.05, 0.55, 0.15, 1.0);
  SetVisualization(trapPdLogical, 0.15, 0.72, 0.22, 1.0);
  SetVisualization(trapAuLogical, 0.58, 0.82, 0.18, 1.0);

  // --------------------------------------------------------------------------
  // Backside Cu/Au heat-sink patch: 300 um x 300 um x 1 um total, attached to
  // the chip bottom surface at z = -0.5 mm.
  // --------------------------------------------------------------------------
  auto* sinkCuLogical = PlaceBox("BacksideSinkCuSolid",
                                 "BacksideSinkCuLV",
                                 "BacksideSinkCuPV",
                                 300.0 * um,
                                 300.0 * um,
                                 800.0 * nm,
                                 G4ThreeVector(0.0,
                                               0.0,
                                               -kChipZ - 400.0 * nm),
                                 copper,
                                 worldLogical);
  auto* sinkAuLogical = PlaceBox("BacksideSinkAuSolid",
                                 "BacksideSinkAuLV",
                                 "BacksideSinkAuPV",
                                 300.0 * um,
                                 300.0 * um,
                                 200.0 * nm,
                                 G4ThreeVector(0.0,
                                               0.0,
                                               -kChipZ - 900.0 * nm),
                                 gold,
                                 worldLogical);
  for (auto* logical : {sinkCuLogical, sinkAuLogical}) {
    logical->SetUserLimits(new G4UserLimits(50.0 * nm));
    RegisterScoringVolume(logical,
                          static_cast<G4int>(GeometryComponent::BacksideHeatSink));
  }
  SetVisualization(sinkCuLogical, 0.45, 0.10, 0.72, 1.0);
  SetVisualization(sinkAuLogical, 0.67, 0.20, 0.85, 1.0);

  // --------------------------------------------------------------------------
  // Lambda/2 CPW resonator. Seven 0.90 mm horizontal runs plus six 0.20 mm
  // turns produce approximately 7.5 mm; the output stem brings the total
  // center-conductor length close to the 7.6 mm baseline for a 6 GHz design.
  // The center conductor uses square turns. The flanking ground strips are
  // shortened near each turn to maintain the physical CPW gaps without creating
  // overlapping Geant4 volumes. This is intended for radiation transport and
  // visualization, not for extracting the microwave eigenfrequency.
  // --------------------------------------------------------------------------
  const G4double cpwWidth = 10.0 * um;
  const G4double cpwGap = 6.0 * um;
  const G4double cpwGroundWidth = 10.0 * um;
  const G4double cpwLeftX = -2.10 * mm;
  const G4double cpwRightX = -1.20 * mm;
  const G4double cpwRunLength = cpwRightX - cpwLeftX;
  const G4double cpwY0 = -0.60 * mm;
  const G4double cpwPitch = 0.20 * mm;
  constexpr G4int kCpwRuns = 7;

  auto* cpwCenterSolid = new G4MultiUnion("CPWResonatorSolid");
  auto* cpwGroundSolid = new G4MultiUnion("CPWGroundSolid");
  const G4double groundOffset = cpwWidth + cpwGap;
  const G4double groundEndClearance = 25.0 * um;

  for (G4int i = 0; i < kCpwRuns; ++i) {
    const G4double y = cpwY0 + i * cpwPitch;
    AddBoxNode(cpwCenterSolid,
               "CPWCenterHorizontal",
               cpwRunLength,
               cpwWidth,
               kMetalThickness,
               G4ThreeVector(0.5 * (cpwLeftX + cpwRightX), y, kMetalCenterZ));

    AddBoxNode(cpwGroundSolid,
               "CPWGroundHorizontalMinus",
               cpwRunLength - 2.0 * groundEndClearance,
               cpwGroundWidth,
               kMetalThickness,
               G4ThreeVector(0.5 * (cpwLeftX + cpwRightX),
                             y - groundOffset,
                             kMetalCenterZ));
    AddBoxNode(cpwGroundSolid,
               "CPWGroundHorizontalPlus",
               cpwRunLength - 2.0 * groundEndClearance,
               cpwGroundWidth,
               kMetalThickness,
               G4ThreeVector(0.5 * (cpwLeftX + cpwRightX),
                             y + groundOffset,
                             kMetalCenterZ));

    if (i + 1 < kCpwRuns) {
      const G4double connectorX = (i % 2 == 0) ? cpwRightX : cpwLeftX;
      const G4double connectorY = y + 0.5 * cpwPitch;
      AddBoxNode(cpwCenterSolid,
                 "CPWCenterTurn",
                 cpwWidth,
                 cpwPitch + cpwWidth,
                 kMetalThickness,
                 G4ThreeVector(connectorX, connectorY, kMetalCenterZ));
    }
  }

  const G4double cpwLastY = cpwY0 + (kCpwRuns - 1) * cpwPitch;
  const G4double resonatorFingerCenterX = -1.08 * mm;
  const G4double resonatorFingerX = 20.0 * um;
  const G4double resonatorFingerY = 80.0 * um;

  // With seven runs, the final run is open at cpwRightX. Extend that endpoint
  // to the resonator-side coupling finger.
  const G4double resonatorFingerLeftEdge =
      resonatorFingerCenterX - 0.5 * resonatorFingerX;
  AddBoxNode(cpwCenterSolid,
             "CPWOutputStem",
             resonatorFingerLeftEdge - cpwRightX,
             cpwWidth,
             kMetalThickness,
             G4ThreeVector(0.5 * (cpwRightX + resonatorFingerLeftEdge),
                           cpwLastY,
                           kMetalCenterZ));
  cpwCenterSolid->Voxelize();
  cpwGroundSolid->Voxelize();

  auto* cpwCenterLogical = new G4LogicalVolume(cpwCenterSolid,
                                                aluminum,
                                                "CPWResonatorLV");
  auto* cpwGroundLogical = new G4LogicalVolume(cpwGroundSolid,
                                                aluminum,
                                                "CPWGroundLV");
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    cpwCenterLogical,
                    "CPWResonatorPV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    cpwGroundLogical,
                    "CPWGroundPV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  for (auto* logical : {cpwCenterLogical, cpwGroundLogical}) {
    logical->SetUserLimits(new G4UserLimits(25.0 * nm));
  }
  RegisterScoringVolume(cpwCenterLogical,
                        static_cast<G4int>(GeometryComponent::CPWResonator));
  RegisterScoringVolume(cpwGroundLogical,
                        static_cast<G4int>(GeometryComponent::CPWGround));
  SetVisualization(cpwCenterLogical, 1.00, 0.55, 0.00, 1.0);
  SetVisualization(cpwGroundLogical, 0.95, 0.72, 0.05, 0.90);

  // --------------------------------------------------------------------------
  // Coupling capacitor: two parallel Al fingers separated by a 10 um gap.
  // The qubit-side finger is routed to the upper edge of the left transmon pad;
  // the resonator-side finger is connected to the CPW output stem.
  // --------------------------------------------------------------------------
  const G4double couplingGap = 10.0 * um;
  const G4double qubitFingerCenterX = resonatorFingerCenterX
                                    + resonatorFingerX
                                    + couplingGap;
  auto* couplingSolid = new G4MultiUnion("CouplingCapacitorSolid");
  AddBoxNode(couplingSolid,
             "ResonatorCouplingFinger",
             resonatorFingerX,
             resonatorFingerY,
             kMetalThickness,
             G4ThreeVector(resonatorFingerCenterX,
                           cpwLastY,
                           kMetalCenterZ));
  AddBoxNode(couplingSolid,
             "QubitCouplingFinger",
             resonatorFingerX,
             resonatorFingerY,
             kMetalThickness,
             G4ThreeVector(qubitFingerCenterX,
                           cpwLastY,
                           kMetalCenterZ));

  const G4double routeY = cpwLastY;
  const G4double routeCenterX = -0.40 * mm;
  const G4double padTopY = 0.15 * mm;
  const G4double qubitFingerRightEdge =
      qubitFingerCenterX + 0.5 * resonatorFingerX;
  AddBoxNode(couplingSolid,
             "CouplingHorizontalRoute",
             routeCenterX - qubitFingerRightEdge,
             cpwWidth,
             kMetalThickness,
             G4ThreeVector(0.5 * (routeCenterX + qubitFingerRightEdge),
                           routeY,
                           kMetalCenterZ));
  AddBoxNode(couplingSolid,
             "CouplingVerticalRoute",
             cpwWidth,
             routeY - padTopY,
             kMetalThickness,
             G4ThreeVector(routeCenterX,
                           0.5 * (routeY + padTopY),
                           kMetalCenterZ));
  couplingSolid->Voxelize();

  auto* couplingLogical = new G4LogicalVolume(couplingSolid,
                                               aluminum,
                                               "CouplingCapacitorLV");
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    couplingLogical,
                    "CouplingCapacitorPV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  couplingLogical->SetUserLimits(new G4UserLimits(25.0 * nm));
  RegisterScoringVolume(couplingLogical,
                        static_cast<G4int>(GeometryComponent::CouplingCapacitor));
  SetVisualization(couplingLogical, 1.00, 0.38, 0.00, 1.0);

  // --------------------------------------------------------------------------
  // Perimeter/bias/control wiring. The thin Al frame and ten spokes reproduce
  // the package-connected wiring visible in the full isometric reference.
  // --------------------------------------------------------------------------
  const G4double wiringWidth = 6.0 * um;
  const G4double frameHalfX = 2.20 * mm;
  const G4double frameHalfY = 1.25 * mm;
  auto* wiringSolid = new G4MultiUnion("OnChipWiringSolid");
  AddBoxNode(wiringSolid,
             "WiringTop",
             2.0 * frameHalfX,
             wiringWidth,
             kMetalThickness,
             G4ThreeVector(0.0, +frameHalfY, kMetalCenterZ));
  AddBoxNode(wiringSolid,
             "WiringBottom",
             2.0 * frameHalfX,
             wiringWidth,
             kMetalThickness,
             G4ThreeVector(0.0, -frameHalfY, kMetalCenterZ));
  AddBoxNode(wiringSolid,
             "WiringLeft",
             wiringWidth,
             2.0 * frameHalfY,
             kMetalThickness,
             G4ThreeVector(-frameHalfX, 0.0, kMetalCenterZ));
  AddBoxNode(wiringSolid,
             "WiringRight",
             wiringWidth,
             2.0 * frameHalfY,
             kMetalThickness,
             G4ThreeVector(+frameHalfX, 0.0, kMetalCenterZ));

  const std::array<G4double, 5> bondPadY = {
      -0.80 * mm, -0.40 * mm, 0.0, +0.40 * mm, +0.80 * mm};
  const G4double onChipPadCenterX = 2.35 * mm;
  const G4double onChipPadSize = 90.0 * um;
  const G4double onChipPadInnerEdge = onChipPadCenterX - 0.5 * onChipPadSize;

  for (G4int i = 0; i < static_cast<G4int>(bondPadY.size()); ++i) {
    const G4double y = bondPadY[i];
    const G4double spokeLength = onChipPadInnerEdge - frameHalfX;
    AddBoxNode(wiringSolid,
               "LeftBondPadSpoke",
               spokeLength,
               wiringWidth,
               kMetalThickness,
               G4ThreeVector(-0.5 * (onChipPadInnerEdge + frameHalfX),
                             y,
                             kMetalCenterZ));
    AddBoxNode(wiringSolid,
               "RightBondPadSpoke",
               spokeLength,
               wiringWidth,
               kMetalThickness,
               G4ThreeVector(+0.5 * (onChipPadInnerEdge + frameHalfX),
                             y,
                             kMetalCenterZ));
  }
  wiringSolid->Voxelize();

  auto* wiringLogical = new G4LogicalVolume(wiringSolid,
                                             aluminum,
                                             "OnChipWiringLV");
  new G4PVPlacement(nullptr,
                    G4ThreeVector(),
                    wiringLogical,
                    "OnChipWiringPV",
                    worldLogical,
                    false,
                    0,
                    kCheckOverlaps);
  wiringLogical->SetUserLimits(new G4UserLimits(25.0 * nm));
  RegisterScoringVolume(wiringLogical,
                        static_cast<G4int>(GeometryComponent::OnChipWiring));
  SetVisualization(wiringLogical, 0.95, 0.58, 0.02, 0.95);

  // --------------------------------------------------------------------------
  // On-chip Al bond pads, external Au package pads, and Au wire-bond arcs.
  // Each wire is a 25 um diameter semicircular G4Torus segment in an x-z plane.
  // --------------------------------------------------------------------------
  auto* onChipPadSolid = new G4Box("OnChipBondPadSolid",
                                   0.5 * onChipPadSize,
                                   0.5 * onChipPadSize,
                                   0.5 * kMetalThickness);
  auto* onChipPadLogical = new G4LogicalVolume(onChipPadSolid,
                                                aluminum,
                                                "OnChipBondPadLV");
  onChipPadLogical->SetUserLimits(new G4UserLimits(25.0 * nm));
  RegisterScoringVolume(onChipPadLogical,
                        static_cast<G4int>(GeometryComponent::OnChipBondPad));
  SetVisualization(onChipPadLogical, 1.00, 0.68, 0.03, 1.0);

  const G4double packagePadCenterX = 2.85 * mm;
  const G4double packagePadSizeX = 100.0 * um;
  const G4double packagePadSizeY = 100.0 * um;
  const G4double packagePadThickness = kMetalThickness;
  auto* packagePadSolid = new G4Box("PackageBondPadSolid",
                                    0.5 * packagePadSizeX,
                                    0.5 * packagePadSizeY,
                                    0.5 * packagePadThickness);
  auto* packagePadLogical = new G4LogicalVolume(packagePadSolid,
                                                 gold,
                                                 "PackageBondPadLV");
  packagePadLogical->SetUserLimits(new G4UserLimits(0.5 * um));
  RegisterScoringVolume(packagePadLogical,
                        static_cast<G4int>(GeometryComponent::PackageBondPad));
  SetVisualization(packagePadLogical, 0.55, 0.30, 0.04, 1.0);

  const G4double wireRadius = 12.5 * um;
  const G4double wireLoopRadius = 0.5 * (packagePadCenterX - onChipPadCenterX);
  auto* wireSolid = new G4Torus("WireBondSolid",
                                0.0,
                                wireRadius,
                                wireLoopRadius,
                                0.0,
                                180.0 * deg);
  auto* wireLogical = new G4LogicalVolume(wireSolid, gold, "WireBondLV");
  wireLogical->SetUserLimits(new G4UserLimits(5.0 * um));
  RegisterScoringVolume(wireLogical,
                        static_cast<G4int>(GeometryComponent::WireBond));
  SetVisualization(wireLogical, 0.63, 0.36, 0.07, 1.0);

  auto* wireRotation = new G4RotationMatrix();
  wireRotation->rotateX(90.0 * deg);
  // A segmented torus is cut normal to its centerline. At each endpoint
  // the circular cut face lies in the x-y plane, so placing the torus origin at
  // the pad top makes the Au wire start exactly on the pad without overlap.
  const G4double wireCenterZ = kMetalThickness;

  G4int padCopyNumber = 0;
  G4int wireCopyNumber = 0;
  for (const G4double y : bondPadY) {
    for (const G4double side : {-1.0, +1.0}) {
      new G4PVPlacement(nullptr,
                        G4ThreeVector(side * onChipPadCenterX,
                                      y,
                                      kMetalCenterZ),
                        onChipPadLogical,
                        "OnChipBondPadPV",
                        worldLogical,
                        false,
                        padCopyNumber,
                        kCheckOverlaps);
      new G4PVPlacement(nullptr,
                        G4ThreeVector(side * packagePadCenterX,
                                      y,
                                      0.5 * packagePadThickness),
                        packagePadLogical,
                        "PackageBondPadPV",
                        worldLogical,
                        false,
                        padCopyNumber,
                        kCheckOverlaps);

      const G4double midpointX = side * 0.5
                               * (onChipPadCenterX + packagePadCenterX);
      new G4PVPlacement(wireRotation,
                        G4ThreeVector(midpointX, y, wireCenterZ),
                        wireLogical,
                        "WireBondPV",
                        worldLogical,
                        false,
                        wireCopyNumber,
                        kCheckOverlaps);
      ++padCopyNumber;
      ++wireCopyNumber;
    }
  }

  G4cout << G4endl
         << "Constructed Module 1 transmon geometry:" << G4endl
         << "  chip             = 5 mm x 3 mm x 0.5 mm" << G4endl
         << "  top Al film      = 100 nm" << G4endl
         << "  transmon pads    = 600 um x 300 um each" << G4endl
         << "  JJ effective area= 1 um x 1 um; AlOx = 2 nm" << G4endl
         << "  CPW length       ~ 7.6 mm (square-turn approximation)" << G4endl
         << "  bond wires       = 10 semicircular Au wires, 25 um diameter"
         << G4endl << G4endl;

  return worldPhysical;
}
