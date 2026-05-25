#ifndef MODULE1_EVENT_ACTION_HH
#define MODULE1_EVENT_ACTION_HH

#include "G4UserEventAction.hh"
#include "globals.hh"

class G4Event;

class EventAction : public G4UserEventAction
{
  public:
    EventAction() = default;
    ~EventAction() override = default;

    void BeginOfEventAction(const G4Event* event) override;
    void EndOfEventAction(const G4Event* event) override;

    void AddEnergyDeposition(G4double edep);

  private:
    G4double fTotalEdep = 0.0;
    G4int fNDepositingSteps = 0;
};

#endif
