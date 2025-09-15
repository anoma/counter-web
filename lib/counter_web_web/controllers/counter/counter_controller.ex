defmodule CounterWebWeb.CounterController do
  use CounterWebWeb, :controller

  alias Anoma.Arm.Resource
  alias Anoma.Arm.MerklePath
  alias CounterExample.Proof
  alias Anoma.Arm.ComplianceUnit
  alias Anoma.Arm.Keypair

  @doc """
  Compliance proof expects three parameters:
   - created ephemeral resource
   - nullifierkey created for the ephemeral counter
   - default merkle path
   - created counter

  The resource is encoded by base64 encoding all binaries.

  The nullifier key is the base64 encoding of the actual key.

  The merkle path is encoded by base64 encoding all leaves.
  E.g., [{<<1, 2, 3>>, false}] => [{"hash": "AQID", "left": false}]

  """
  def compliance_proof(
        conn,
        params = %{"nf_key" => _, "consumed" => _, "created" => _, "merkle_path" => _}
      ) do
    params = Anoma.Json.keys_to_atoms(params)
    # decode the individual parts of the params into their respective structs and values
    nf_key = Base.decode64!(params.nf_key)
    consumed = Resource.from_map(params.consumed)
    created = Resource.from_map(params.created)
    merkle_path = MerklePath.from_map(params.merkle_path)

    {compliance_unit, rcv} = Proof.compliance(consumed, nf_key, merkle_path, created)

    render(conn, :ephemeral_counter, %{compliance_unit: compliance_unit, rcv: rcv})
  end

  def logic_proof(
        conn,
        params = %{
          "consumed" => _,
          "consumed_nf_key" => _,
          "created" => _,
          "sender_keypair" => _,
          "receiver_keypair" => _
        }
      ) do
    params = Anoma.Json.keys_to_atoms(params)
    # decode the individual parts of the params into their respective structs and values
    consumed_nf_key = Base.decode64!(params.consumed_nf_key)
    consumed = Resource.from_map(params.consumed)
    created = Resource.from_map(params.created)
    sender_keypair = Keypair.from_map(params.sender_keypair)
    receiver_keypair = Keypair.from_map(params.receiver_keypair)

    {consumed_proof, created_proof} =
      Proof.logic(consumed, consumed_nf_key, created, sender_keypair, receiver_keypair)

    # conver tfrom LogicVerifier to LogicVerifierInputs for the webclients
    consumed_proof = Anoma.Arm.convert(consumed_proof)
    created_proof = Anoma.Arm.convert(created_proof)
    render(conn, :logic_proofs, %{consumed_proof: consumed_proof, created_proof: created_proof})
  end

  def delta_proof(conn, params = %{"transaction" => _}) do
    params = Anoma.Json.keys_to_atoms(params)
    transaction = Anoma.Arm.Transaction.from_map(params.transaction)
    transaction = Anoma.Arm.Transaction.generate_delta_proof(transaction)
    render(conn, :delta_proof, %{transaction: transaction})
  end
end
