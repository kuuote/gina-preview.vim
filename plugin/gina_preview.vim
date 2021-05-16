let g:gina_preview_oneside = get(g:, "gina_preview_oneside", 1)
command! -bang GinaPreview call gina_preview#open(<bang>1)
