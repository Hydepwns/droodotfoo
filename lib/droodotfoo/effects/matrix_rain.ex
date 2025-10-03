defmodule Droodotfoo.Effects.MatrixRain do
  @moduledoc """
  Matrix rain effect for the terminal droo.foo.
  """

  @width 48
  @height 16
  @chars "abcdefghijklmnopqrstuvwxyz01234567890!@#$%^&*()"

  def generate_frame(tick) do
    for y <- 0..(@height - 1) do
      for x <- 0..(@width - 1) do
        # Create a falling effect based on position and tick
        intensity = calculate_intensity(x, y, tick)

        if intensity > 0 do
          char = random_char(x, y, tick)
          shade = intensity_to_shade(intensity)
          {char, shade}
        else
          {" ", :normal}
        end
      end
    end
  end

  defp calculate_intensity(x, y, tick) do
    # Create columns that fall at different speeds
    column_offset = :erlang.phash2(x) / 4_294_967_296
    fall_position = rem(tick + round(column_offset * 100), @height * 2)

    distance = abs(y - fall_position)

    if distance < 3 do
      max(0, 3 - distance)
    else
      0
    end
  end

  defp intensity_to_shade(intensity) do
    case intensity do
      3 -> :bright
      2 -> :normal
      1 -> :dim
      _ -> :hidden
    end
  end

  defp random_char(x, y, tick) do
    index = rem(:erlang.phash2({x, y, div(tick, 2)}), String.length(@chars))
    String.at(@chars, index)
  end
end
