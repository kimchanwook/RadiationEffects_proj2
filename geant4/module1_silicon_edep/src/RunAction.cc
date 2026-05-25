#include "RunAction.hh"

#include "G4AnalysisManager.hh"
#include "G4Run.hh"
#include "G4SystemOfUnits.hh"
#include "G4UnitsTable.hh"
#include "G4ios.hh"

#include <filesystem>

RunAction::RunAction()
{
  auto analysisManager = G4AnalysisManager::Instance();

  // This requires that Geant4 was built with -DGEANT4_USE_HDF5=ON.
  // The output file written by BeginOfRunAction will be:
  //   output/module1_silicon_edep.hdf5
  analysisManager->SetDefaultFileType("hdf5");
  analysisManager->SetVerboseLevel(1);

  // Ntuple 0: per-step energy-deposition records in silicon.
  analysisManager->CreateNtuple("steps", "Per-step energy deposition inside silicon");
  analysisManager->CreateNtupleIColumn("eventID");
  analysisManager->CreateNtupleIColumn("trackID");
  analysisManager->CreateNtupleIColumn("parentID");
  analysisManager->CreateNtupleIColumn("stepID");
  analysisManager->CreateNtupleIColumn("pdgCode");
  analysisManager->CreateNtupleDColumn("x_um");
  analysisManager->CreateNtupleDColumn("y_um");
  analysisManager->CreateNtupleDColumn("z_um");
  analysisManager->CreateNtupleDColumn("edep_eV");
  analysisManager->CreateNtupleDColumn("stepLength_um");
  analysisManager->FinishNtuple();

  // Ntuple 1: event-level total deposited energy in silicon.
  analysisManager->CreateNtuple("events", "Event-level deposited energy inside silicon");
  analysisManager->CreateNtupleIColumn("eventID");
  analysisManager->CreateNtupleDColumn("totalEdep_eV");
  analysisManager->CreateNtupleIColumn("nDepositingSteps");
  analysisManager->FinishNtuple();
}

void RunAction::BeginOfRunAction(const G4Run*)
{
  std::filesystem::create_directories("output");

  auto analysisManager = G4AnalysisManager::Instance();
  analysisManager->OpenFile(fOutputBaseName);

  G4cout << "Module 1 output file base name: " << fOutputBaseName
         << "  (HDF5 output expected: " << fOutputBaseName << ".hdf5)" << G4endl;
}

void RunAction::EndOfRunAction(const G4Run*)
{
  auto analysisManager = G4AnalysisManager::Instance();
  analysisManager->Write();
  analysisManager->CloseFile();

  G4cout << "Module 1 HDF5 output written." << G4endl;
}
