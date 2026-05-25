#include "PrimaryGeneratorAction.hh"

#include "G4Event.hh"
#include "G4ParticleGun.hh"
#include "G4ParticleTable.hh"
#include "G4SystemOfUnits.hh"
#include "G4ThreeVector.hh"

PrimaryGeneratorAction::PrimaryGeneratorAction()
{
  fParticleGun = new G4ParticleGun(1);

  // Default source: one 10 MeV proton incident from above the silicon target.
  // Silicon spans z = [-25 um, +25 um], so z = +30 um starts just above the top face.
  // These defaults can be overridden from a macro using /gun commands.
  auto particle = G4ParticleTable::GetParticleTable()->FindParticle("proton");
  fParticleGun->SetParticleDefinition(particle);
  fParticleGun->SetParticleEnergy(10.0 * MeV);
  fParticleGun->SetParticlePosition(G4ThreeVector(0.0, 0.0, 30.0 * um));
  fParticleGun->SetParticleMomentumDirection(G4ThreeVector(0.0, 0.0, -1.0));
}

PrimaryGeneratorAction::~PrimaryGeneratorAction()
{
  delete fParticleGun;
}

void PrimaryGeneratorAction::GeneratePrimaries(G4Event* event)
{
  fParticleGun->GeneratePrimaryVertex(event);
}
