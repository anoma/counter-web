defmodule Counter do
  @moduledoc """
  Interface functions to create counter resources and transactions.
  """

  alias Anoma.Arm
  alias Anoma.Arm.MerklePath
  alias Anoma.Arm.Action
  alias Anoma.Arm.NullifierKey
  alias Anoma.Arm.Transaction
  alias Anoma.Arm.DeltaWitness
  alias Anoma.Arm.NullifierKeyCommitment
  alias Anoma.Arm.Resource

  alias CounterExample.Create
  alias CounterExample.Proof

  @spec create_keypair :: {NullifierKey.t(), NullifierKeyCommitment.t()}
  def create_keypair do
    NullifierKey.random_pair()
  end

  @doc """
  If a user wants to generate a resource, they need to provide us with a
  nullifier key.

  The commitment is used to "own" the resource. The resource can then only be
  consumed using the nullifier key that was used to generate the commitment. The
  nullifier key is used to create a nullifier to eventually consume the
  resource.

  The second keypair in the function arguments is the keypair owned by the
  creator of the resources. These keys are used to encrypt the discovery payload
  for the indexer.
  """
  def init_counter(nullifier_key, keypair) do
    # create an ephemeral resource
    {eph_counter, eph_nf_key} = create_ephemeral_counter()

    # create a counter for the user with their nullifier key.
    # First, create a commitment based on the given key.
    commitment = NullifierKey.commit(nullifier_key)
    crt_counter = Create.create_new_counter(commitment, eph_counter, eph_nf_key)

    # create the compliance proof for these two resources
    {compliance_unit, rcv} =
      Proof.compliance(eph_counter, eph_nf_key, MerklePath.default(), crt_counter)

    # generate the resource logics proof note that the keypair is twice the one
    # of the caller. the init counter is called by Bob, and bob wants to decrypt
    # the discovery payload too. in case of a transfer this would be the keypair
    # of the receiver.
    {consumed_proof, created_proof} =
      Proof.logic(eph_counter, eph_nf_key, crt_counter, keypair, keypair)

    consumed_proof = Arm.convert(consumed_proof)
    created_proof = Arm.convert(created_proof)

    # create an action for this transaction
    action = %Action{
      compliance_units: [compliance_unit],
      logic_verifier_inputs: [consumed_proof, created_proof]
    }

    # create the delta proof for this transaction
    delta_witness = %DeltaWitness{signing_key: rcv}

    %Transaction{
      actions: [action],
      delta_proof: {:witness, delta_witness}
    }
  end

  @doc """
  To create an ephemeral resource, we do not need the user's key.
  To create an ephemeral resource we can generate an arbitrary random keypair.
  """
  @spec create_ephemeral_counter :: {Resource.t(), NullifierKey.t()}
  def create_ephemeral_counter() do
    {key, commitment} = NullifierKey.random_pair()
    ephemeral = Create.create_ephemeral_counter(commitment)
    {ephemeral, key}
  end
end
