#ifndef MODULE1_TRANSMON_EVENT_ACTION_HH
#define MODULE1_TRANSMON_EVENT_ACTION_HH

#include "GeometryComponent.hh"
#include "G4UserEventAction.hh"
#include "globals.hh"

#include <array>

class G4Event;

class EventAction : public G4UserEventAction
{
  public:
    EventAction() = default;
    ~EventAction() override = default;

    void BeginOfEventAction(const G4Event* event) override;
    void EndOfEventAction(const G4Event* event) override;

    void AddEnergyDeposition(G4int componentID, G4double edep);

  private:
    G4double fTotalEdep = 0.0;
    G4int fNDepositingSteps = 0;
    std::array<G4double, kNumberOfGeometryComponents> fComponentEdep{};
    std::array<G4int, kNumberOfGeometryComponents> fComponentDepositingSteps{};
};

#endif
