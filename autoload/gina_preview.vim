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
  if a:resize && len(gettabinfo(tabpagenr())[0]['windows']) != 1
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
  let type = l[0:1]
  let file = l[3:]
  let is_vertical = &diffopt =~# "vertical"
  let opener = is_vertical ? "split" : "vsplit"
  if type ==# "??"
    execute "keepalt rightbelow" opener file
    return s:gotowin(v:true)
  elseif type =~# '\(\s\|M\)\(\s\|M\)'
    let opener_opt = "--opener=" .. opener
    let oneside = g:gina_preview_oneside ? "--oneside" : ""
    silent! execute "Gina patch" opener_opt oneside file
  else
    return
  endif
  
  call s:gotowin(v:true)
endfunction

function! s:on(scheme) abort
  if !get(t:, "gina_preview", 0)
    return
  elseif a:scheme ==# "status"
    " gina.vimのコールバック内でプレビュー表示をするとバグるので
    " タイマーを挟む
    call timer_start(0, {id->s:open()})
  endif
endfunction

function! s:cursor_moved() abort
  if !get(t:, 'gina_preview', 0) || bufname() !~# '^gina.*status$'
    return
  endif
  let oldline = get(b:, 'gina_preview_cursor', 1)
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

  if !s:subscribed
    call gina#core#emitter#subscribe("command:called", function("s:on"))
    let s:subscribed = 1
  endif
  augroup gina-preview
    autocmd!
    autocmd CursorMoved * ++nested call s:cursor_moved()
  augroup END
endfunction
