#ifndef MODULE1_TRANSMON_DETECTOR_CONSTRUCTION_HH
#define MODULE1_TRANSMON_DETECTOR_CONSTRUCTION_HH

#include "G4VUserDetectorConstruction.hh"
#include "globals.hh"

#include <unordered_map>

class G4LogicalVolume;
class G4Material;
class G4VPhysicalVolume;

class DetectorConstruction : public G4VUserDetectorConstruction
{
  public:
    DetectorConstruction() = default;
    ~DetectorConstruction() override = default;

    G4VPhysicalVolume* Construct() override;

    G4int GetComponentID(const G4LogicalVolume* logicalVolume) const;

  private:
    void RegisterScoringVolume(G4LogicalVolume* logicalVolume, G4int componentID);
    void SetVisualization(G4LogicalVolume* logicalVolume,
                          G4double red,
                          G4double green,
                          G4double blue,
                          G4double alpha = 1.0) const;

    std::unordered_map<const G4LogicalVolume*, G4int> fComponentByLogicalVolume;
};

#endif
