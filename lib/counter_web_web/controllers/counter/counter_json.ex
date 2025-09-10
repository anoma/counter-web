defmodule CounterWebWeb.CounterJSON do
  def ephemeral_counter(%{compliance_unit: cu, rcv: rcv}) do
    %{compliance_unit: cu, rcv: Base.encode64(rcv)}
  end

  def logic_proofs(%{consumed_proof: consumed_proof, created_proof: created_proof}) do
    %{consumed_proof: consumed_proof, created_proof: created_proof}
  end
end
