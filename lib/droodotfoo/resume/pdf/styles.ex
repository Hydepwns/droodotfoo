defmodule Droodotfoo.Resume.PDF.Styles do
  @moduledoc """
  CSS stylesheet definitions for PDF resume generation.
  Each format has its own typography and layout style.
  """

  @doc """
  Get the CSS stylesheet for the specified format.
  """
  def get(:technical), do: technical_styles()
  def get(:executive), do: executive_styles()
  def get(:minimal), do: minimal_styles()
  def get(:detailed), do: detailed_styles()
  def get(_), do: technical_styles()

  defp technical_styles do
    """
    body {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.4;
      margin: 0;
      padding: 20px;
      background: #fff;
      color: #000;
    }
    .header {
      border-bottom: 2px solid #000;
      padding-bottom: 10px;
      margin-bottom: 20px;
    }
    .name {
      font-size: 24px;
      font-weight: bold;
      margin: 0;
    }
    .title {
      font-size: 14px;
      color: #333;
      margin: 5px 0;
    }
    .contact {
      font-size: 10px;
      margin-top: 10px;
    }
    .section {
      margin: 20px 0;
    }
    .section-title {
      font-size: 14px;
      font-weight: bold;
      border-bottom: 1px solid #000;
      padding-bottom: 2px;
      margin-bottom: 10px;
    }
    .experience-item, .project-item {
      margin-bottom: 15px;
    }
    .company, .project-name {
      font-weight: bold;
      font-size: 12px;
    }
    .position, .technologies {
      font-style: italic;
      color: #666;
    }
    .date {
      float: right;
      font-size: 10px;
      color: #666;
    }
    .description {
      margin: 5px 0;
      white-space: pre-line;
    }
    .achievements {
      margin: 5px 0;
    }
    .achievement {
      margin: 3px 0;
      padding-left: 10px;
    }
    .tech-stack {
      font-size: 9px;
      color: #888;
      margin-top: 5px;
    }
    """
  end

  defp executive_styles do
    """
    body {
      font-family: 'Times New Roman', serif;
      font-size: 12px;
      line-height: 1.6;
      margin: 0;
      padding: 30px;
      background: #fff;
      color: #000;
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .name {
      font-size: 28px;
      font-weight: bold;
      margin: 0;
    }
    .title {
      font-size: 16px;
      color: #333;
      margin: 10px 0;
    }
    .contact {
      font-size: 11px;
      margin-top: 15px;
    }
    .section {
      margin: 25px 0;
    }
    .section-title {
      font-size: 16px;
      font-weight: bold;
      border-bottom: 2px solid #000;
      padding-bottom: 5px;
      margin-bottom: 15px;
    }
    .executive-summary {
      font-size: 13px;
      line-height: 1.8;
      text-align: justify;
    }
    .achievement {
      margin: 10px 0;
      padding-left: 20px;
    }
    .experience-item {
      margin-bottom: 20px;
    }
    .company {
      font-weight: bold;
      font-size: 14px;
    }
    .position {
      font-style: italic;
      color: #666;
    }
    .date {
      float: right;
      font-size: 11px;
      color: #666;
    }
    """
  end

  defp minimal_styles do
    """
    body {
      font-family: 'Arial', sans-serif;
      font-size: 12px;
      line-height: 1.5;
      margin: 0;
      padding: 25px;
      background: #fff;
      color: #000;
    }
    .header {
      text-align: center;
      margin-bottom: 25px;
    }
    .name {
      font-size: 22px;
      font-weight: bold;
      margin: 0;
    }
    .title {
      font-size: 14px;
      color: #333;
      margin: 5px 0;
    }
    .contact {
      font-size: 11px;
      margin-top: 10px;
    }
    .section {
      margin: 20px 0;
    }
    .section-title {
      font-size: 14px;
      font-weight: bold;
      color: #000;
      margin-bottom: 10px;
    }
    .item {
      margin-bottom: 12px;
    }
    .item-title {
      font-weight: bold;
    }
    .item-subtitle {
      color: #666;
      font-size: 11px;
    }
    .item-date {
      float: right;
      font-size: 10px;
      color: #666;
    }
    """
  end

  defp detailed_styles do
    """
    body {
      font-family: 'Georgia', serif;
      font-size: 11px;
      line-height: 1.6;
      margin: 0;
      padding: 25px;
      background: #fff;
      color: #000;
    }
    .header {
      border-bottom: 3px solid #000;
      padding-bottom: 15px;
      margin-bottom: 25px;
    }
    .name {
      font-size: 26px;
      font-weight: bold;
      margin: 0;
    }
    .title {
      font-size: 15px;
      color: #333;
      margin: 8px 0;
    }
    .contact {
      font-size: 11px;
      margin-top: 12px;
    }
    .section {
      margin: 25px 0;
    }
    .section-title {
      font-size: 15px;
      font-weight: bold;
      border-bottom: 2px solid #000;
      padding-bottom: 3px;
      margin-bottom: 12px;
    }
    .experience-item, .project-item {
      margin-bottom: 20px;
      page-break-inside: avoid;
    }
    .company, .project-name {
      font-weight: bold;
      font-size: 13px;
    }
    .position, .role {
      font-style: italic;
      color: #666;
      font-size: 12px;
    }
    .date {
      float: right;
      font-size: 10px;
      color: #666;
    }
    .description {
      margin: 8px 0;
      white-space: pre-line;
      font-size: 11px;
    }
    .achievements {
      margin: 8px 0;
    }
    .achievement {
      margin: 5px 0;
      padding-left: 15px;
    }
    .tech-stack {
      font-size: 9px;
      color: #888;
      margin-top: 5px;
    }
    .project-url {
      font-size: 10px;
      color: #0066cc;
    }
    """
  end
end
