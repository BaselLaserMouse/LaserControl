function varargout=integrateLaser(hLaser)
% Integrate laser GUI into ScanImage
%
% Purpose
% Place a menu item for the laser GUI into ScanImage
% 
% e.g. 
% >> M=dummyLaser;
% >> laserControl.scanimage.integrateLaser(M)
%

if ~isa(hLaser,'laserControl.laser')
    fprintf('laserControl.scanimage.integrateLaser requires input of class laserControl.laser\n');
end

main_window = findall(0, 'Type', 'Figure', 'Name', 'MAIN CONTROLS');

if isempty(main_window)
    fprintf('Can not find ScanImage\n')
    success=false;
    return
end


%Find the view menu and add a menu entry if it does not already exist
mitem=findall(0,'Tag','laserControl_SI');
if isempty(mitem)
    view_menu  = findobj(main_window, 'Tag', 'View');
    mitem = uimenu(view_menu, 'Text', 'Laser control');
    mitem.Tag='laserControl_SI';
end

mitem.UserData=struct('hLaser',hLaser);
mitem.MenuSelectedFcn = @laserControl.scanimage.openLaserGUI;

success=true;

if nargout>0
	varargout{1}=success;
end