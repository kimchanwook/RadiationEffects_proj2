#include "RunAction.hh"

#include "GeometryComponent.hh"

#include "G4AnalysisManager.hh"
#include "G4Run.hh"

#include <filesystem>
#include <fstream>

RunAction::RunAction()
{
  auto* analysisManager = G4AnalysisManager::Instance();
  analysisManager->SetVerboseLevel(1);
  analysisManager->SetDefaultFileType("hdf5");

  // Ntuple 0: per-step deposition in every registered transmon/package component.
  analysisManager->CreateNtuple("steps", "Per-step energy deposition in transmon geometry");
  analysisManager->CreateNtupleIColumn("eventID");
  analysisManager->CreateNtupleIColumn("trackID");
  analysisManager->CreateNtupleIColumn("parentID");
  analysisManager->CreateNtupleIColumn("stepID");
  analysisManager->CreateNtupleIColumn("pdgCode");
  analysisManager->CreateNtupleIColumn("componentID");
  analysisManager->CreateNtupleIColumn("copyNo");
  analysisManager->CreateNtupleDColumn("x_um");
  analysisManager->CreateNtupleDColumn("y_um");
  analysisManager->CreateNtupleDColumn("z_um");
  analysisManager->CreateNtupleDColumn("edep_eV");
  analysisManager->CreateNtupleDColumn("stepLength_um");
  analysisManager->FinishNtuple();

  // Ntuple 1: one row per event.
  analysisManager->CreateNtuple("events", "Event-level deposited-energy total");
  analysisManager->CreateNtupleIColumn("eventID");
  analysisManager->CreateNtupleDColumn("totalEdep_eV");
  analysisManager->CreateNtupleIColumn("nDepositingSteps");
  analysisManager->CreateNtupleIColumn("nHitComponents");
  analysisManager->FinishNtuple();

  // Ntuple 2: sparse per-event, per-component summary.
  analysisManager->CreateNtuple("component_events", "Per-event energy by geometry component");
  analysisManager->CreateNtupleIColumn("eventID");
  analysisManager->CreateNtupleIColumn("componentID");
  analysisManager->CreateNtupleDColumn("edep_eV");
  analysisManager->CreateNtupleIColumn("nDepositingSteps");
  analysisManager->FinishNtuple();
}

void RunAction::BeginOfRunAction(const G4Run*)
{
  std::filesystem::create_directories("output");

  std::ofstream componentMap("output/component_map.csv");
  componentMap << "componentID,name\n";
  for (G4int componentID = 0;
       componentID < kNumberOfGeometryComponents;
       ++componentID) {
    componentMap << componentID << ','
                 << GeometryComponentName(componentID) << '\n';
  }

  auto* analysisManager = G4AnalysisManager::Instance();
  analysisManager->OpenFile(fOutputBaseName);

  G4cout << "Transmon Module 1 output: " << fOutputBaseName
         << ".hdf5" << G4endl;
}

void RunAction::EndOfRunAction(const G4Run*)
{
  auto* analysisManager = G4AnalysisManager::Instance();
  analysisManager->Write();
  analysisManager->CloseFile();

  G4cout << "Transmon energy-deposition output written." << G4endl;
}
