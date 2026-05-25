#include "ActionInitialization.hh"
#include "DetectorConstruction.hh"

#include "FTFP_BERT.hh"
#include "G4RunManagerFactory.hh"
#include "G4UImanager.hh"
#include "G4UIExecutive.hh"
#include "G4VisExecutive.hh"

int main(int argc, char** argv)
{
  auto* runManager = G4RunManagerFactory::CreateRunManager(G4RunManagerType::Default);

  auto* detectorConstruction = new DetectorConstruction();
  runManager->SetUserInitialization(detectorConstruction);

  // User-requested reference physics list: FTFP_BERT.
  runManager->SetUserInitialization(new FTFP_BERT());

  runManager->SetUserInitialization(new ActionInitialization(detectorConstruction));

  auto* visManager = new G4VisExecutive();
  visManager->Initialize();

  auto* uiManager = G4UImanager::GetUIpointer();

  if (argc == 1) {
    // Interactive mode.
    auto* ui = new G4UIExecutive(argc, argv);
    uiManager->ApplyCommand("/control/execute init_vis.mac");
    ui->SessionStart();
    delete ui;
  } else {
    // Batch mode: pass a macro as the first command-line argument.
    const G4String command = "/control/execute ";
    const G4String fileName = argv[1];
    uiManager->ApplyCommand(command + fileName);
  }

  delete visManager;
  delete runManager;

  return 0;
}
