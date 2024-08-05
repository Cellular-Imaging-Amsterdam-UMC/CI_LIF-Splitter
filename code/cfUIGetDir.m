function [pathname] = cfUIGetDir(start_path, dialog_title)
    % Pick multiple directories 

    import javax.swing.JFileChooser;

    if strcmpi(start_path,''); start_path=pwd; end
    
    jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

    jchooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    jchooser.setDialogTitle(dialog_title);

    jchooser.setMultiSelectionEnabled(true);

    status = jchooser.showOpenDialog([]);

    if status == JFileChooser.APPROVE_OPTION
        jFile = jchooser.getSelectedFiles();
        pathname{size(jFile, 1)}=[];
        for i=1:size(jFile, 1)
            pathname{i} = char(jFile(i).getAbsolutePath);
        end

    elseif status == JFileChooser.CANCEL_OPTION
        pathname = [];
    else
        error('Error occured while picking file.');
    end
end
