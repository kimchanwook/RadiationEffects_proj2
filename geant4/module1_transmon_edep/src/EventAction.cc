#include "EventAction.hh"

#include "G4AnalysisManager.hh"
#include "G4Event.hh"
#include "G4SystemOfUnits.hh"

#include <algorithm>

void EventAction::BeginOfEventAction(const G4Event*)
{
  fTotalEdep = 0.0;
  fNDepositingSteps = 0;
  fComponentEdep.fill(0.0);
  fComponentDepositingSteps.fill(0);
}

void EventAction::AddEnergyDeposition(const G4int componentID,
                                      const G4double edep)
{
  if (componentID < 0 || componentID >= kNumberOfGeometryComponents || edep <= 0.0) {
    return;
  }

  fTotalEdep += edep;
  ++fNDepositingSteps;
  fComponentEdep[componentID] += edep;
  ++fComponentDepositingSteps[componentID];
}

void EventAction::EndOfEventAction(const G4Event* event)
{
  auto* analysisManager = G4AnalysisManager::Instance();
  const G4int eventID = event->GetEventID();

  G4int nHitComponents = 0;
  for (G4int componentID = 0;
       componentID < kNumberOfGeometryComponents;
       ++componentID) {
    if (fComponentEdep[componentID] > 0.0) {
      ++nHitComponents;
    }
  }

  // Ntuple 1: one total row per event.
  analysisManager->FillNtupleIColumn(1, 0, eventID);
  analysisManager->FillNtupleDColumn(1, 1, fTotalEdep / eV);
  analysisManager->FillNtupleIColumn(1, 2, fNDepositingSteps);
  analysisManager->FillNtupleIColumn(1, 3, nHitComponents);
  analysisManager->AddNtupleRow(1);

  // Ntuple 2: one row per component with nonzero deposited energy.
  for (G4int componentID = 0;
       componentID < kNumberOfGeometryComponents;
       ++componentID) {
    if (fComponentEdep[componentID] <= 0.0) {
      continue;
    }
    analysisManager->FillNtupleIColumn(2, 0, eventID);
    analysisManager->FillNtupleIColumn(2, 1, componentID);
    analysisManager->FillNtupleDColumn(2, 2, fComponentEdep[componentID] / eV);
    analysisManager->FillNtupleIColumn(2, 3, fComponentDepositingSteps[componentID]);
    analysisManager->AddNtupleRow(2);
  }
}
