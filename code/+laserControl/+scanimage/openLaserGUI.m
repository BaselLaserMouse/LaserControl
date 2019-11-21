function varargout=openLaserGUI(~,~)


f=findall(0,'Tag','laserControl_SI');
hGUI=laserControl.gui.laser_view_si_hooked(f.UserData.hLaser);

if nargout>0
	varargout{1}=hGUI;
end
