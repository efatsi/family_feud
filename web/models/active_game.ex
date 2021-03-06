defmodule FamilyFeud.ActiveGame do
  use FamilyFeud.Web, :model

  schema "active_games" do
    field :active, :boolean, default: true
    field :team_1_score, :integer, default: 0
    field :team_2_score, :integer, default: 0
    belongs_to :game, Game

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:active, :team_1_score, :team_2_score, :game_id])
    |> validate_required([:active, :team_1_score, :team_2_score, :game_id])
  end

  def create(game) do
    changeset(%ActiveGame{}, %{game_id: game.id}) |> Repo.insert
  end

  def get_active_round(active_game, round \\ nil) do
    game            = Repo.get(Game, active_game.game_id)
    round           = round || Game.first_round(game)
    active_round    =
      Repo.get_by(ActiveRound, active_game_id: active_game.id, active: true) ||
      Repo.get_by(ActiveFastMoneyRound, active_game_id: active_game.id, active: true)

    if !active_round do
      case round do
        %Round{} ->
          {:ok, active_round} = ActiveRound.create(active_game, round)

          if round == Game.ordered_rounds(game) |> List.last do
            {:ok, active_round} = ActiveRound.update(active_round, %{last_round: true})
          end
        %FastMoneyRound{} ->
          {:ok, active_round} = ActiveFastMoneyRound.create(active_game, round)

          if round == Game.ordered_rounds(game) |> List.last do
            {:ok, active_round} = ActiveFastMoneyRound.update(active_round, %{last_round: true})
          end
      end
    end

    active_round
  end
end
