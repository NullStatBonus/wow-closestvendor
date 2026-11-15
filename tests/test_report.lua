package.path="tests/?.lua;"..package.path
local H=require("harness");local eq=H.eq
local created,released={},{}
local gui={}
function gui:Create(kind)
    local w={kind=kind,callbacks={}}
    function w:SetTitle(v)self.title=v end
    function w:SetStatusText(v)self.status=v end
    function w:SetLayout(v)self.layout=v end
    function w:SetCallback(k,fn)self.callbacks[k]=fn end
    function w:SetLabel(v)self.label=v end
    function w:DisableButton(v)self.buttonDisabled=v end
    function w:SetText(v)self.text=v end
    function w:AddChild(child)self.box=child end
    function w:SetFocus()self.focused=true end
    function w:HighlightText()self.highlighted=true end
    function w:Release()gui:Release(self)end
    created[#created+1]=w;return w
end
function gui:Release(w)released[#released+1]=w end
local ns=H.locale({})
local chunk=assert(loadfile("ClosestVendor/Report.lua"))
setfenv(chunk,setmetatable({LibStub=function()return gui end},{__index=_G}));chunk("ClosestVendor",ns)
eq(ns.Report.Show("first report"),true,"standard report opens")
local w=created[1];eq(w.kind,"Frame","same Ace window as KT")
eq(w.title,"Closest Vendor debug report","report title")
eq(w.layout,"Fill","report fills standard scrollable window")
eq(w.status:find("Ctrl+C",1,true)~=nil,true,"copy instructions visible")
eq(w.box.kind,"MultiLineEditBox","standard scrollable edit box")
eq(w.box.buttonDisabled,true,"no submit button")
eq(w.box.focused and w.box.highlighted,true,"ready to copy")
w.box.text="accidental edit";w.box.callbacks.OnTextChanged(w.box)
eq(w.box.text,"first report","report text cannot be changed")
ns.Report.Show("new report");eq(released[1],w,"repeat releases previous window")
w=created[3];eq(w.box.text,"new report","repeat shows latest report")
w.callbacks.OnClose(w);eq(released[2],w,"close releases widgets")
ns.Report.Show("after close");eq(created[5].box.text,"after close","can reopen after close")
H.done()
