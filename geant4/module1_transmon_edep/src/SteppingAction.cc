#include "SteppingAction.hh"

#include "DetectorConstruction.hh"
#include "EventAction.hh"

#include "G4AnalysisManager.hh"
#include "G4Event.hh"
#include "G4EventManager.hh"
#include "G4LogicalVolume.hh"
#include "G4ParticleDefinition.hh"
#include "G4Step.hh"
#include "G4StepPoint.hh"
#include "G4SystemOfUnits.hh"
#include "G4ThreeVector.hh"
#include "G4TouchableHandle.hh"
#include "G4Track.hh"
#include "G4VPhysicalVolume.hh"

SteppingAction::SteppingAction(const DetectorConstruction* detectorConstruction,
                               EventAction* eventAction)
  : fDetectorConstruction(detectorConstruction),
    fEventAction(eventAction)
{}

void SteppingAction::UserSteppingAction(const G4Step* step)
{
  const auto* preStepPoint = step->GetPreStepPoint();
  const auto touchable = preStepPoint->GetTouchableHandle();
  const auto* volume = touchable->GetVolume();
  if (!volume) {
    return;
  }

  const G4int componentID =
      fDetectorConstruction->GetComponentID(volume->GetLogicalVolume());
  if (componentID < 0) {
    return;
  }

  const G4double edep = step->GetTotalEnergyDeposit();
  if (edep <= 0.0) {
    return;
  }

  fEventAction->AddEnergyDeposition(componentID, edep);

  const auto* postStepPoint = step->GetPostStepPoint();
  const G4ThreeVector position =
      0.5 * (preStepPoint->GetPosition() + postStepPoint->GetPosition());
  const auto* track = step->GetTrack();
  const G4int eventID = G4EventManager::GetEventManager()
                          ->GetConstCurrentEvent()
                          ->GetEventID();

  auto* analysisManager = G4AnalysisManager::Instance();
  analysisManager->FillNtupleIColumn(0, 0, eventID);
  analysisManager->FillNtupleIColumn(0, 1, track->GetTrackID());
  analysisManager->FillNtupleIColumn(0, 2, track->GetParentID());
  analysisManager->FillNtupleIColumn(0, 3, track->GetCurrentStepNumber());
  analysisManager->FillNtupleIColumn(0, 4,
                                      track->GetDefinition()->GetPDGEncoding());
  analysisManager->FillNtupleIColumn(0, 5, componentID);
  analysisManager->FillNtupleIColumn(0, 6, touchable->GetCopyNumber());
  analysisManager->FillNtupleDColumn(0, 7, position.x() / um);
  analysisManager->FillNtupleDColumn(0, 8, position.y() / um);
  analysisManager->FillNtupleDColumn(0, 9, position.z() / um);
  analysisManager->FillNtupleDColumn(0, 10, edep / eV);
  analysisManager->FillNtupleDColumn(0, 11, step->GetStepLength() / um);
  analysisManager->AddNtupleRow(0);
}
