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

function! s:gotowin(resize) abort
  let ti = gettabinfo(tabpagenr())[0]
  let found = v:false
  for wid in ti.windows
    let name = bufname(winbufnr(wid))
    if name =~ '^gina.*status$'
      let found = v:true
      call win_gotoid(wid)
    endif
  endfor
  if !found
    echomsg 'gina-preview: status window is not found'
    return
  endif
  if a:resize
    if &diffopt =~# "vertical"
      execute "resize" &lines / 3
    else
      execute "vertical resize" &columns / 3
    endif
    let view = get(b:, 'gina_preview_view', {})
    call winrestview(view)
  endif
endfunction

function! s:open() abort
  call s:gotowin(v:false)
  silent! only
  let l = substitute(getline("."), "\<Esc>[^m]\\+m", "", "g")
  let type = l[0:2]
  let file = l[3:]
  let is_vertical = &diffopt =~# "vertical"
  let opener = is_vertical ? "split" : "vsplit"
  if type =~# "?"
    execute "keepalt rightbelow" opener file
    return s:gotowin(v:true)
  else
    let opener_opt = "--opener=" .. opener
    let oneside = g:gina_preview_oneside ? "--oneside" : ""
    silent! execute "Gina patch" opener_opt oneside file
  endif
  
  call s:gotowin(is_vertical)
endfunction

function! s:on(scheme) abort
  if !get(t:, "gina_preview", 0)
    return
  elseif a:scheme ==# "patch"
    call s:gotowin(v:false)
  elseif a:scheme ==# "status"
    echomsg 'status'
    call s:open()
  endif
endfunction

function! s:cursor_moved() abort
  let oldline = get(b:, 'gina_preview_cursor', -1)
  let curline = line('.')
  if oldline != curline
    let b:gina_preview_cursor = curline
    let b:gina_preview_view = winsaveview()
    call s:open()
  endif
endfunction

function! gina_preview#open(usetab) abort
  if a:usetab
    keepalt tab split
  endif
  let t:gina_preview = 1
  call s:status()

  autocmd CursorMoved <buffer> ++nested call s:cursor_moved()
  if !s:subscribed
    call gina#core#emitter#subscribe("command:called", function("s:on"))
    let s:subscribed = 1
  endif
endfunction
