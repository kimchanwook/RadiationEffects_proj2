#include "SteppingAction.hh"

#include "DetectorConstruction.hh"
#include "EventAction.hh"

#include "G4AnalysisManager.hh"
#include "G4Event.hh"
#include "G4EventManager.hh"
#include "G4LogicalVolume.hh"
#include "G4ParticleDefinition.hh"
#include "G4Step.hh"
#include "G4SystemOfUnits.hh"
#include "G4Track.hh"
#include "G4VPhysicalVolume.hh"

SteppingAction::SteppingAction(const DetectorConstruction* detectorConstruction,
                               EventAction* eventAction)
  : fDetectorConstruction(detectorConstruction),
    fEventAction(eventAction)
{}

void SteppingAction::UserSteppingAction(const G4Step* step)
{
  if (!fScoringVolume) {
    fScoringVolume = fDetectorConstruction->GetScoringVolume();
  }

  const auto preStepPoint = step->GetPreStepPoint();
  const auto volume = preStepPoint->GetTouchableHandle()->GetVolume();
  if (!volume) return;

  const auto logicalVolume = volume->GetLogicalVolume();
  if (logicalVolume != fScoringVolume) return;

  const G4double edep = step->GetTotalEnergyDeposit();
  if (edep <= 0.0) return;

  fEventAction->AddEnergyDeposition(edep);

  const auto postStepPoint = step->GetPostStepPoint();
  const auto pos = 0.5 * (preStepPoint->GetPosition() + postStepPoint->GetPosition());
  const auto track = step->GetTrack();

  const G4int eventID = G4EventManager::GetEventManager()
                          ->GetConstCurrentEvent()
                          ->GetEventID();

  const G4int trackID = track->GetTrackID();
  const G4int parentID = track->GetParentID();
  const G4int stepID = track->GetCurrentStepNumber();
  const G4int pdgCode = track->GetDefinition()->GetPDGEncoding();

  auto analysisManager = G4AnalysisManager::Instance();

  // Fill ntuple 0: per-step energy-deposition record.
  analysisManager->FillNtupleIColumn(0, 0, eventID);
  analysisManager->FillNtupleIColumn(0, 1, trackID);
  analysisManager->FillNtupleIColumn(0, 2, parentID);
  analysisManager->FillNtupleIColumn(0, 3, stepID);
  analysisManager->FillNtupleIColumn(0, 4, pdgCode);
  analysisManager->FillNtupleDColumn(0, 5, pos.x() / um);
  analysisManager->FillNtupleDColumn(0, 6, pos.y() / um);
  analysisManager->FillNtupleDColumn(0, 7, pos.z() / um);
  analysisManager->FillNtupleDColumn(0, 8, edep / eV);
  analysisManager->FillNtupleDColumn(0, 9, step->GetStepLength() / um);
  analysisManager->AddNtupleRow(0);
}
