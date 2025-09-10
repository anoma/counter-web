require Protocol
Protocol.derive(JSON.Encoder, Anoma.Arm.Transaction)
Protocol.derive(JSON.Encoder, Anoma.Arm.Action)
Protocol.derive(JSON.Encoder, Anoma.Arm.ComplianceUnit)
Protocol.derive(JSON.Encoder, Anoma.Arm.LogicVerifierInputs)
Protocol.derive(JSON.Encoder, Anoma.Arm.DeltaProof)
Protocol.derive(JSON.Encoder, Anoma.Arm.AppData)
Protocol.derive(JSON.Encoder, Anoma.Arm.ExpirableBlob)
Protocol.derive(JSON.Encoder, Anoma.Arm.Resource)

defimpl JSON.Encoder, for: Anoma.Arm.Resource do
  def encode(term, _encoder) do
    term
    |> Map.delete(:__struct__)
    |> Map.update!(:logic_ref, &Base.encode64/1)
    |> Map.update!(:label_ref, &Base.encode64/1)
    |> Map.update!(:value_ref, &Base.encode64/1)
    |> Map.update!(:nonce, &Base.encode64/1)
    |> Map.update!(:rand_seed, &Base.encode64/1)
    |> Map.update!(:nk_commitment, &Base.encode64/1)
    |> JSON.encode!()
  end
end

defimpl JSON.Encoder, for: Anoma.Arm.MerklePath do
  def encode(term, _encoder) do
    ""
  end
end

# defmodule Counter.JSON do
#   def encode(term) do
#     JSON.encode!(term, &encode/2)
#   end

#   def encode(term, cont) when is_binary(term) do
#     JSON.protocol_encode(Base.encode64(term), cont)
#   end

#   def encode(term, cont) when is_tuple(term) do
#     JSON.protocol_encode(Tuple.to_list(term), cont)
#   end

#   def encode(term, cont) do
#     JSON.protocol_encode(term, cont)
#   end
# end
