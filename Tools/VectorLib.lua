-- do some nice things on position tables using black magic
VectorLib = {}
function VectorLib.Add( _p1, _p2)
	return {X = _p1.X + _p2.X, Y = _p1.Y + _p2.Y}
end
function VectorLib.Sub( _p1, _p2)
	return {X = _p1.X - _p2.X, Y = _p1.Y - _p2.Y}
end
function VectorLib.ScalarProd( _p, _t)
	return {X = _t*_p.X, Y = _t*_p.Y}
end
function VectorLib.DotProd( _p1, _p2)
	return _p1.X*_p2.X + _p1.Y*_p2.Y
end
function VectorLib.Norm( _p)
	return math.sqrt(_p.X*_p.X + _p.Y*_p.Y)
end
function VectorLib.Rescale( _p, _l)	-- takes vector _p and scales it to length _l
	return VectorLib.ScalarProd( _p, _l / VectorLib.Norm( _p))
end
function VectorLib.GetOrthVector( _p) -- finds vector v with v orthogonal to _p
	return {X = _p.Y, Y = -_p.X}
end
function VectorLib.GetAngle( _p)
	local viewX = _p.X
	local viewY = _p.Y
	local length = math.sqrt(viewX*viewX + viewY*viewY)
	viewX = viewX / length
	viewY = viewY / length
	local acoss = math.acos( viewX) --maps to [0, Pi]
	local asinn = math.sin( viewY) --maps to [ -pi/2, pi/2]
	local orientation = 0
	if asinn >= 0 then
		orientation = math.deg( acoss)
	else
		orientation = math.deg( 2*math.pi - acoss)
	end
	return orientation
end
