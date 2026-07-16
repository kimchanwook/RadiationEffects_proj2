#ifndef MODULE1_TRANSMON_RUN_ACTION_HH
#define MODULE1_TRANSMON_RUN_ACTION_HH

#include "G4UserRunAction.hh"
#include "globals.hh"

class G4Run;

class RunAction : public G4UserRunAction
{
  public:
    RunAction();
    ~RunAction() override = default;

    void BeginOfRunAction(const G4Run* run) override;
    void EndOfRunAction(const G4Run* run) override;

  private:
    G4String fOutputBaseName = "output/module1_transmon_edep";
};

#endif
