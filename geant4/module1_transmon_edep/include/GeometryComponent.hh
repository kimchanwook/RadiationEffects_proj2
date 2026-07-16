#ifndef MODULE1_TRANSMON_GEOMETRY_COMPONENT_HH
#define MODULE1_TRANSMON_GEOMETRY_COMPONENT_HH

#include "globals.hh"

// Stable integer IDs written to the analysis ntuples. Keep existing values fixed
// so downstream readers can compare runs made with different particle-gun settings.
enum class GeometryComponent : G4int
{
  Substrate = 0,
  CPWResonator = 1,
  CPWGround = 2,
  CouplingCapacitor = 3,
  LeftTransmonNode = 4,
  RightTransmonNode = 5,
  JJLeftElectrode = 6,
  JJBarrier = 7,
  JJRightElectrode = 8,
  NormalMetalTrap = 9,
  BacksideHeatSink = 10,
  OnChipWiring = 11,
  OnChipBondPad = 12,
  PackageBondPad = 13,
  WireBond = 14
};

inline constexpr G4int kNumberOfGeometryComponents = 15;

inline const char* GeometryComponentName(const G4int componentID)
{
  switch (static_cast<GeometryComponent>(componentID)) {
    case GeometryComponent::Substrate:          return "substrate";
    case GeometryComponent::CPWResonator:       return "cpw_resonator";
    case GeometryComponent::CPWGround:          return "cpw_ground";
    case GeometryComponent::CouplingCapacitor:  return "coupling_capacitor";
    case GeometryComponent::LeftTransmonNode:   return "left_transmon_node";
    case GeometryComponent::RightTransmonNode:  return "right_transmon_node";
    case GeometryComponent::JJLeftElectrode:    return "jj_left_electrode";
    case GeometryComponent::JJBarrier:          return "jj_barrier_alox";
    case GeometryComponent::JJRightElectrode:   return "jj_right_electrode";
    case GeometryComponent::NormalMetalTrap:    return "normal_metal_trap";
    case GeometryComponent::BacksideHeatSink:   return "backside_heat_sink";
    case GeometryComponent::OnChipWiring:       return "on_chip_wiring";
    case GeometryComponent::OnChipBondPad:      return "on_chip_bond_pad";
    case GeometryComponent::PackageBondPad:     return "package_bond_pad";
    case GeometryComponent::WireBond:           return "wire_bond";
  }
  return "unknown";
}

#endif
