#ifndef MODULE1_ACTION_INITIALIZATION_HH
#define MODULE1_ACTION_INITIALIZATION_HH

#include "G4VUserActionInitialization.hh"

class DetectorConstruction;

class ActionInitialization : public G4VUserActionInitialization
{
  public:
    explicit ActionInitialization(const DetectorConstruction* detectorConstruction);
    ~ActionInitialization() override = default;

    void BuildForMaster() const override;
    void Build() const override;

  private:
    const DetectorConstruction* fDetectorConstruction = nullptr;
};

#endif
