macro outer(args)
	macro inner(i)
		\{{i}}
		{{debug()}}
	end
	{{debug()}}
end

outer(1)
inner(2)
