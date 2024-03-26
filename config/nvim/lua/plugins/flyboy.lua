return {
  "CamdenClark/flyboy",

  config = {
    model = "gpt-4-turbo-preview",

    templates = {
      testes = {
        template_fn = function(sources)
          return "Testes " .. sources.visual()
        end,
      },
    },
  },
}
