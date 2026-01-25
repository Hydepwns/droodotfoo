defmodule Droodotfoo.Content.SVG.Filters do
  @moduledoc """
  SVG filter definitions (blur, glow, shadow, noise, etc).
  """

  @doc """
  Creates a blur filter definition.
  """
  @spec blur(String.t(), number) :: String.t()
  def blur(id, std_deviation) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceGraphic" stdDeviation="#{std_deviation}"/>
    </filter>
    """
  end

  @doc """
  Creates a glow filter definition.
  """
  @spec glow(String.t(), String.t(), number) :: String.t()
  def glow(id, _color, intensity) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceGraphic" stdDeviation="#{intensity}"/>
      <feColorMatrix type="matrix" values="
        1 0 0 0 0
        0 1 0 0 0
        0 0 1 0 0
        0 0 0 #{intensity * 2} 0"/>
      <feBlend in="SourceGraphic" in2="blur" mode="normal"/>
    </filter>
    """
  end

  @doc """
  Creates a drop shadow filter definition.
  """
  @spec shadow(String.t(), number, number, number) :: String.t()
  def shadow(id, dx, dy, blur_amount) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceAlpha" stdDeviation="#{blur_amount}"/>
      <feOffset dx="#{dx}" dy="#{dy}" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.5"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    """
  end

  @doc """
  Creates a turbulence/noise filter definition.
  """
  @spec noise(String.t(), number) :: String.t()
  def noise(id, base_frequency) do
    """
    <filter id="#{id}">
      <feTurbulence type="fractalNoise" baseFrequency="#{base_frequency}" numOctaves="4" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0"/>
      <feBlend in="SourceGraphic" in2="noise" mode="multiply"/>
    </filter>
    """
  end

  @doc """
  Creates a displacement map filter for distortion effects.
  """
  @spec displacement(String.t(), number) :: String.t()
  def displacement(id, scale) do
    """
    <filter id="#{id}">
      <feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="turbulence"/>
      <feDisplacementMap in2="turbulence" in="SourceGraphic" scale="#{scale}" xChannelSelector="R" yChannelSelector="G"/>
    </filter>
    """
  end

  @doc """
  Creates a lighting filter for 3D emboss effects.
  """
  @spec lighting(String.t(), String.t()) :: String.t()
  def lighting(id, light_color) do
    """
    <filter id="#{id}">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feSpecularLighting result="specOut" specularExponent="20" lighting-color="#{light_color}">
        <fePointLight x="50" y="50" z="200"/>
      </feSpecularLighting>
      <feComposite in="SourceGraphic" in2="specOut" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"/>
    </filter>
    """
  end
end
