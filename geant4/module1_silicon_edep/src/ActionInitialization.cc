#include "ActionInitialization.hh"

#include "DetectorConstruction.hh"
#include "EventAction.hh"
#include "PrimaryGeneratorAction.hh"
#include "RunAction.hh"
#include "SteppingAction.hh"

ActionInitialization::ActionInitialization(const DetectorConstruction* detectorConstruction)
  : fDetectorConstruction(detectorConstruction)
{}

void ActionInitialization::BuildForMaster() const
{
  SetUserAction(new RunAction());
}

void ActionInitialization::Build() const
{
  SetUserAction(new PrimaryGeneratorAction());
  SetUserAction(new RunAction());

  auto eventAction = new EventAction();
  SetUserAction(eventAction);

  SetUserAction(new SteppingAction(fDetectorConstruction, eventAction));
}
