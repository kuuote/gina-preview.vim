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

function! s:gotowin(is_vertical) abort
  call win_gotoid(t:winid_gina)
  if a:is_vertical
    execute "resize" &lines / 3
  else
    execute "vertical resize" &columns / 3
  endif
  let view = get(b:, 'gina_preview_view', {})
  call winrestview(view)
  
endfunction

function! s:on(scheme) abort
  let is_vertical = &diffopt =~# "vertical"

  if !get(t:, "gina_preview", 0)
    return
  elseif a:scheme ==# "patch"
    return s:gotowin(is_vertical)
  elseif a:scheme !=# "status"
    return
  endif

  call win_gotoid(t:winid_gina)
  silent! only
  let l = substitute(getline("."), "\<Esc>[^m]\\+m", "", "g")
  let type = l[0:2]
  let file = l[3:]
  let opener = is_vertical ? "split" : "vsplit"
  if type =~# "?"
    execute "keepalt rightbelow" opener file
    return s:gotowin(is_vertical)
  else
    let opener_opt = "--opener=" .. opener
    let oneside = g:gina_preview_oneside ? "--oneside" : ""
    silent! execute "Gina patch" opener_opt oneside file
  endif
endfunction

function! s:cursor_moved() abort
  let oldline = get(b:, 'gina_preview_cursor', -1)
  let curline = line('.')
  if oldline != curline
    let b:gina_preview_cursor = curline
    let b:gina_preview_view = winsaveview()
    call s:on('status')
  endif
endfunction

function! gina_preview#open(usetab) abort
  if a:usetab
    keepalt tab split
  endif
  let t:gina_preview = 1
  call s:status()
  let t:winid_gina = win_getid()

  autocmd CursorMoved <buffer> ++nested call s:cursor_moved()
  " autocmd CursorMoved <buffer> call s:on("status")
  if !s:subscribed
    call gina#core#emitter#subscribe("command:called", function("s:on"))
    let s:subscribed = 1
  endif
endfunction
