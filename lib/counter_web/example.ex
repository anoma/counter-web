defmodule Example do
  @moduledoc """
  This is an example of how to create a counter transacation by using the API to
  generate proofs.
  """

  alias Anoma.Arm
  alias Anoma.Arm.Action
  alias Anoma.Arm.DeltaWitness
  alias Anoma.Arm.MerklePath
  alias Anoma.Arm.NullifierKey
  alias Anoma.Arm.Transaction
  alias CounterExample.Create
  alias CounterExample.Proof

  def init do
    # ----------------------------------------------------------------------------
    # Create the resources client side
    # client side ~= javascript or whatever

    # create an ephemeral counter.
    # the keypair for this counter is always random.
    {eph_key, eph_nk_com} = NullifierKey.random_pair()
    ephemeral = Create.create_ephemeral_counter(eph_nk_com)

    # create a new counter resource based on the ephemeral counter that was just
    # created
    #
    # the keys here are probably derived from the user's keys.
    {_crtd_key, crtd_nk_com} = NullifierKey.random_pair()
    created = Create.create_new_counter(crtd_nk_com, ephemeral, eph_key)

    # ----------------------------------------------------------------------------
    # POST request to generate compliance proof

    # the merklepath has to be explicitly encoded into json
    merkle_path = MerklePath.default()
    # create the compliance proof via the API.
    json = %{
      consumed: ephemeral,
      nf_key: Base.encode64(eph_key),
      created: created,
      merkle_path: Anoma.Arm.MerklePath.to_map(merkle_path)
    }

    json_str = Jason.encode!(json)

    IO.puts(json_str)

    response =
      Req.post!("http://localhost:4000/api/compliance-proof",
        body: json_str,
        headers: [{"content-type", "application/json"}]
      )

    {compliance_unit, rcv} =
      case response do
        %{status: 200, body: result} ->
          # keys are strings, but we need them to be atoms.
          result = Anoma.Json.keys_to_atoms(result)
          compliance_unit = Anoma.Arm.ComplianceUnit.from_map(result.compliance_unit)
          rcv = Base.decode64!(result.rcv)
          {compliance_unit, rcv}
      end

    # ----------------------------------------------------------------------------
    # Generate keypairs for the logic proofs (discovery key and whatnot)
    # create a random keypair to encrypt the ciphertext
    sender_keypair = Arm.random_key_pair()
    receiver_keypair = Arm.random_key_pair()

    # ----------------------------------------------------------------------------
    # POST request to generate logic proof

    json = %{
      consumed: ephemeral,
      consumed_nf_key: Base.encode64(eph_key),
      created: created,
      sender_keypair: sender_keypair,
      receiver_keypair: receiver_keypair
    }

    json_str = Jason.encode!(json)

    IO.puts(json_str)

    response =
      Req.post!("http://localhost:4000/api/logic-proof",
        body: json_str,
        headers: [{"content-type", "application/json"}]
      )

    {consumed_proof, created_proof} =
      case response do
        %{status: 200, body: result} ->
          # keys are strings, but we need them to be atoms.
          result = Anoma.Json.keys_to_atoms(result)

          consumed_proof =
            Anoma.Arm.LogicVerifierInputs.from_map(result.consumed_proof)

          created_proof =
            Anoma.Arm.LogicVerifierInputs.from_map(result.created_proof)

          {consumed_proof, created_proof}
      end

    # ----------------------------------------------------------------------------
    # Create the actions and delta witness

    # create an action for this transaction
    action = %Action{
      compliance_units: [compliance_unit],
      logic_verifier_inputs: [consumed_proof, created_proof]
    }

    delta_witness = %DeltaWitness{signing_key: rcv}

    transaction = %Transaction{
      actions: [action],
      delta_proof: {:witness, delta_witness}
    }

    # ----------------------------------------------------------------------------
    # POST request to generate delta proof

    json = %{transaction: transaction}

    json_str = Jason.encode!(json)

    IO.puts(json_str)

    response =
      Req.post!("http://localhost:4000/api/delta-proof",
        body: json_str,
        headers: [{"content-type", "application/json"}]
      )

    IO.inspect(response)
    # {consumed_proof, created_proof} =
    transaction =
      case response do
        %{status: 200, body: result} ->
          # keys are strings, but we need them to be atoms.
          result = Anoma.Json.keys_to_atoms(result)
          Anoma.Arm.Transaction.from_map(result.transaction)
      end

    # # ----------------------------------------------------------------------------
    # # Here you have a complete transaction!

    # verify the transaction
    if Arm.verify_transaction(transaction) do
      {:ok, transaction}
    else
      {:error, :verify_failed, transaction}
    end
  end
end
