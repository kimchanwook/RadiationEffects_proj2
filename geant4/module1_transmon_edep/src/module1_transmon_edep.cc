#include "ActionInitialization.hh"
#include "DetectorConstruction.hh"

#include "FTFP_BERT.hh"
#include "G4RunManagerFactory.hh"
#include "G4UIExecutive.hh"
#include "G4UImanager.hh"
#include "G4VisExecutive.hh"

int main(int argc, char** argv)
{
  auto* runManager =
      G4RunManagerFactory::CreateRunManager(G4RunManagerType::Serial);

  auto* detectorConstruction = new DetectorConstruction();
  runManager->SetUserInitialization(detectorConstruction);
  runManager->SetUserInitialization(new FTFP_BERT());
  runManager->SetUserInitialization(new ActionInitialization(detectorConstruction));

  auto* visManager = new G4VisExecutive();
  visManager->Initialize();

  auto* uiManager = G4UImanager::GetUIpointer();

  if (argc == 1) {
    auto* ui = new G4UIExecutive(argc, argv);
    uiManager->ApplyCommand("/control/execute init_vis.mac");
    ui->SessionStart();
    delete ui;
  } else {
    const G4String command = "/control/execute ";
    uiManager->ApplyCommand(command + G4String(argv[1]));
  }

  delete visManager;
  delete runManager;
  return 0;
}
