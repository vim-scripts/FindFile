" vim600: set foldmethod=marker:
" $Id:$
" PURPOSE: {{{
"   - FindFile: Switch to an auto-completing buffer to open a file quickly.
"
" REQUIREMENTS:
"   - Vim 7.0
"
" USAGE:
"   Put this file in your ~/.vim/plugin directory.
"   If you are working on a project, go to the root directory of the project,
"   then execute:
"
"       :FindFileCache .<CR>
"       or
"       :FC .<CR>
"
"   This will recursively parse the directory and create the internal cache.
"
"   You can also put in multiple arguments in :FC:
"
"       :FC /dir1 /dir2 /dir3
"
"   You can add to the cache by calling :FC again.  File with the same path
"   will not be added to the cache twice.
"
"   To find a file:
"
"       :FindFile<CR>
"       or
"       :FF<CR>
"
"   This opens a scratch buffer that you can type in the file name.  Press
"   <Esc> will quit the buffer, while <Enter> will select and edit the file.
"
"   To clear the internal cache, do:
"
"       :FindFileCacheClear<CR>
"       or
"       :FCC<CR>
"
"
"   You can put the following lines in your ~/.vimrc in order to invoke
"   FindFile quickly by hitting <C-f>:
"
"       :nmap <C-f> :FindFile<CR>
"
"   By default, all the *.o, *.pyc, and */tmp/* files will be ignored, in
"   addition to the wildignore patterns.  You can customize this by setting in
"   your .vimrc:
"
"       let g:FindFileIgnore = ['*.o', '*.pyc', '*/tmp/*']
"
" CREDITS:
"   Please mail any comment/suggestion/patch to 
"   William Lee <wl1012@yahoo.com>
"
" Section: Mappings {{{1
command! -nargs=* -complete=dir FindFileCache call <SID>CacheDir(<f-args>)
command! -nargs=* -complete=dir FC call <SID>CacheDir(<f-args>)

command! FindFileCacheClear call <SID>CacheClear()
command! FCC call <SID>CacheClear()

command! FindFile call <SID>FindFile()
command! FF call <SID>FindFile()

" Global Settings {{{1
if !exists("g:FindFileIgnore")
    let g:FindFileIgnore = ['*.o', '*.pyc', '*/tmp/*']
endif

" Section: Functions {{{1
" File cache to store the filename
let s:fileCache = {}
" The sorted keys for the dictionary
let s:fileKeys = []

fun! CompleteFile(findstart, base)
	if a:findstart
		return 0
	else
		" TODO: We can definitely do a binary search on the keys instead of
		" doing a learn match.
		for k in s:fileKeys
			let matchExpr = <SID>EscapeChars(a:base)
			if match(k, matchExpr) == 0
				call complete_add({'word': k, 'menu': s:fileCache[k], 'icase' : 1})
			endif
			if complete_check()
				break
			endif
		endfor
		return []
	endif
endfun


fun! <SID>FindFile()
	new FindFile
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	" Map the keys for completion
	" TODO: Need to add complete list of completion keys
	let compKeys = [
				\'a','A',
				\'b','B',
				\'c','C',
				\'c','C',
				\'d','D',
				\'e','E',
				\'f','F',
				\'g','G',
				\'h','H',
				\'i','I',
				\'j','J',
				\'k','K',
				\'l','L',
				\'m','M',
				\'n','N',
				\'o','O',
				\'p','P',
				\'q','Q',
				\'r','R',
				\'s','S',
				\'t','T',
				\'u','U',
				\'v','V',
				\'w','W',
				\'x','X',
				\'y','Y',
				\'z','Z',
				\'.',
				\',',
				\'_',
				\]
	for k in compKeys
		let remapCmd = "inoremap <buffer> " . k . " " . k . "<C-X><C-O>"
		exe remapCmd
	endfor

	inoremap <buffer> <CR> <ESC>:silent call <SID>EditFile(getline("."))<CR>
	inoremap <buffer> <ESC> <C-[>:silent call <SID>QuitBuff()<CR>
	setlocal completeopt=menuone,longest,preview
	setlocal omnifunc=CompleteFile
	setlocal noignorecase
	startinsert
endfun

fun! <SID>CacheClear()
	let s:fileCache = {}
	let s:fileKeys = []
endfun

fun! <SID>EscapeChars(toEscape)
	return escape(a:toEscape, ". \!\@\#\$\%\^\&\*\(\)\-\=\\\|\~\`\'")
endfun

fun! <SID>CacheDir(...)
	for d in a:000
		"Creates the dictionary that will parse all files recursively
		for i in g:FindFileIgnore
			let s = "setlocal wildignore+=" . i
			exe s
		endfor
		let files = glob(d . "/**")
		for i in g:FindFileIgnore
			let s = "setlocal wildignore-=" . i
			exe s
		endfor
		let ctr = 0
		for f in split(files, "\n")
			let fname = fnamemodify(f, ":t")
			let fpath = fnamemodify(f, ":p")
			" If the cache already has this entry, we'll just skip it
			let hasEntry = 0
			while has_key(s:fileCache, fname)
				if s:fileCache[fname] == fpath
					let hasEntry = 1
					break
				endif
				let fnameArr = split(fname, ":")
				if len(fnameArr) > 1
					let fname = fnameArr[0] . ":" . (fnameArr[1] + 1)
				else
					let fname = fname . ":1"
				endif
			endwhile
			if !hasEntry
				let s:fileCache[fname] = fpath
				let ctr = ctr + 1
			endif
		endfor
		let s:fileKeys = sort(copy(keys(s:fileCache)))
		echo "Found " . ctr . " new files in '" . d . "'. Cache has " . len(s:fileKeys) . " entries."
	endfor
endfun

fun! <SID>QuitBuff()
	silent exe "bd!"
endfun

fun! <SID>EditFile(f)
	" Closes the buffer
	let fileToOpen = a:f
	if has_key(s:fileCache, a:f)
		let fileToOpen = s:fileCache[a:f]
	else
		" We attempt to find the file in the list if it is not a
		" complete key
		let matchExpr = <SID>EscapeChars(a:f)
		for k in s:fileKeys
			if match(k, matchExpr) == 0
				let fileToOpen = s:fileCache[k]
				break
			endif
		endfor
	endif
	if filereadable(fileToOpen)
		silent exe "bd!"
		silent exe "edit " . fileToOpen
		echo "File: " . fileToOpen
	else
		echo "File " . fileToOpen . " not found. Run ':FileFindCache .' to refresh if necessary."
	endif
endfun
