return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  config = function()
    require('typescript-tools').setup {
      settings = {
        tsserver_max_memory = 16384,
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
        },
        tsserver_format_options = {
          baseIndentSize = 0,
          indentSize = 2,
          tabSize = 2,
          indentStyle = 'Block',
          newLineCharacter = '\n',
          convertTabsToSpaces = true,
          insertSpaceAfterCommaDelimiter = true,
          insertSpaceAfterSemicolonInForStatements = true,
          insertSpaceBeforeAndAfterBinaryOperators = true,
          insertSpaceAfterConstructor = false,
          insertSpaceAfterKeywordsInControlFlowStatements = true,
          insertSpaceAfterFunctionKeywordForAnonymousFunctions = false,
          insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = false,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
          insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
          insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
          insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
          insertSpaceAfterTypeAssertion = false,
          insertSpaceBeforeFunctionParenthesis = false,
          insertSpaceBeforeTypeAnnotation = false,
          placeOpenBraceOnNewLineForFunctions = false,
          placeOpenBraceOnNewLineForControlBlocks = false,
        },
      },
    }
  end,
}
