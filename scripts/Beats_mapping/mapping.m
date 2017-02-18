clc
clear
% Get the scenario pointer
networkFolder=findFolder.BEATS_network();
fileName='210E_for_estimation_v5_links_fixed.xml';
pd=ScenarioPtr;
pd=pd.load(fullfile(networkFolder,fileName),false);

% Get the freeway structure
freeway_structure=pd.get_freeway_structure;
linear_freeway_idx=freeway_structure.linear_fwy_ind;

% Reorganize the types and link lengths
types=pd.get_link_types;
types=types(linear_freeway_idx);
lengths=pd.get_link_lengths;
lengths=lengths(linear_freeway_idx);

% Get the link IDs
linkIDs=freeway_structure.linear_fwy_link_ids;

% Get the positions
linkPos=pd.get_link_pos(linkIDs);

linkTable=[num2cell(linkIDs),types',num2cell(lengths)',num2cell(linkPos)];
xlswrite('BEATSLinkTable.xlsx',{'Link ID','Type','Length','Latitute','Longitute'},'BEATS')
xlswrite('BEATSLinkTable.xlsx',linkTable,'BEATS','A2')

