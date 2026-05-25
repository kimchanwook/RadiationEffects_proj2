#include "EventAction.hh"

#include "G4AnalysisManager.hh"
#include "G4Event.hh"
#include "G4SystemOfUnits.hh"

void EventAction::BeginOfEventAction(const G4Event*)
{
  fTotalEdep = 0.0;
  fNDepositingSteps = 0;
}

void EventAction::EndOfEventAction(const G4Event* event)
{
  auto analysisManager = G4AnalysisManager::Instance();

  const G4int eventID = event->GetEventID();

  // Fill ntuple 1: event summary.
  analysisManager->FillNtupleIColumn(1, 0, eventID);
  analysisManager->FillNtupleDColumn(1, 1, fTotalEdep / eV);
  analysisManager->FillNtupleIColumn(1, 2, fNDepositingSteps);
  analysisManager->AddNtupleRow(1);
}

void EventAction::AddEnergyDeposition(G4double edep)
{
  fTotalEdep += edep;
  ++fNDepositingSteps;
}
