let s:subscribed = 0

function! s:status() abort
  let repo = finddir(".git", expand("%:p:h") .. ";")
  if !empty(repo)
    let repo = fnamemodify(repo, ":p")
    let root = fnamemodify(repo, ":h:h") " ディレクトリ名が展開された場合末尾に/が付く
    execute "tcd" root
    Gina status -s
  else
    throw "Not a git repository."
  endif
endfunction

function! s:on(scheme) abort
  let is_vertical = &diffopt =~# "vertical"

  if !get(t:, "gina_preview", 0)
    return
  elseif a:scheme ==# "patch"
    call win_gotoid(t:winid_gina)
    if is_vertical
      execute "resize" &lines / 3
    else
      execute "vertical resize" &columns / 3
    endif
    return
  elseif a:scheme !=# "status"
    return
  endif

  call win_gotoid(t:winid_gina)
  silent! only
  let l = substitute(getline("."), "\<Esc>[^m]\\+m", "", "g")
  let file = l[3:]
  let opener = "--opener=" .. (is_vertical ? "split" : "vsplit")
  let oneside = g:gina_preview_oneside ? "--oneside" : ""
  silent! execute "Gina patch" opener oneside file
endfunction

function! gina_preview#open(usetab) abort
  if a:usetab
    tab split
  endif
  let t:gina_preview = 1
  call s:status()
  let t:winid_gina = win_getid()

  nnoremap <buffer> j j:call <SID>on("status")<CR>
  nnoremap <buffer> k k:call <SID>on("status")<CR>
  " autocmd CursorMoved <buffer> call s:on("status")
  if !s:subscribed
    call gina#core#emitter#subscribe("command:called", function("s:on"))
    let s:subscribed = 1
  endif
endfunction
